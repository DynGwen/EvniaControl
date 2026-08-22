import AppKit
import ApplicationServices
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published private(set) var isConnected = false
    @Published private(set) var displayName = "Evnia"
    @Published private(set) var statusMessage = "Searching for display…"

    @Published var brightness: Int
    @Published var volume: Int
    @Published private(set) var isMuted = false
    @Published private(set) var keyboardAuthorized = false

    @Published private(set) var attenuationDB: Int
    @Published private(set) var attenuationStatus: String?

    @Published var keyboardControlEnabled: Bool {
        didSet {
            defaults.set(
                keyboardControlEnabled,
                forKey: Keys.keyboardEnabled
            )
        }
    }

    @Published var brightnessStep: Int {
        didSet {
            defaults.set(
                brightnessStep,
                forKey: Keys.brightnessStep
            )
        }
    }

    @Published var volumeStep: Int {
        didSet {
            defaults.set(
                volumeStep,
                forKey: Keys.volumeStep
            )
        }
    }

    private enum Keys {
        static let keyboardEnabled = "keyboardControlEnabled"
        static let brightnessStep = "brightnessStep"
        static let volumeStep = "volumeStep"
        static let attenuationDB =
            "recovery1011.attenuationDB"
        static let savedBrightness =
            "monitorState.brightness"
        static let savedVolume =
            "monitorState.volume"
    }

    private let defaults = UserDefaults.standard
    private let driver = M1DDCDriver.shared
    private let audio = AudioController()

    private var brightnessWriteTask: Task<Void, Never>?
    private var volumeWriteTask: Task<Void, Never>?
    private var refreshTimer: Timer?
    private var lastAudibleVolume = 50

    private init() {
        let storedDefaults = UserDefaults.standard
        let restoredBrightness = Self.clampPercent(
            storedDefaults.object(
                forKey: Keys.savedBrightness
            ) as? Int ?? 50
        )
        let restoredVolume = Self.clampPercent(
            storedDefaults.object(
                forKey: Keys.savedVolume
            ) as? Int ?? 50
        )

        brightness = restoredBrightness
        volume = restoredVolume

        keyboardControlEnabled = storedDefaults.object(
            forKey: Keys.keyboardEnabled
        ) as? Bool ?? true

        brightnessStep = 5
        volumeStep = 5

        // Migrate any legacy 6% values from earlier builds.
        storedDefaults.set(
            5,
            forKey: Keys.brightnessStep
        )
        storedDefaults.set(
            5,
            forKey: Keys.volumeStep
        )

        attenuationDB = Self.quantizedDB(
            storedDefaults.object(
                forKey: Keys.attenuationDB
            ) as? Int ?? 0
        )

        // All required stored properties are initialized above.
        lastAudibleVolume = restoredVolume > 0
            ? restoredVolume
            : 50
    }

    func start() {
        updateKeyboardAuthorization()

        Task {
            await refresh()
        }

        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: 30,
            repeats: true
        ) { _ in
            Task { @MainActor in
                await AppModel.shared.refresh()
            }
        }

        applyAttenuation()
    }

    func updateKeyboardAuthorization() {
        keyboardAuthorized = AXIsProcessTrusted()
    }

    func refresh() async {
        do {
            let snapshot = try await driver.refresh()

            displayName = snapshot.display.name
            isConnected = true
            statusMessage = "Connected"

            let hasSavedBrightness =
                defaults.object(
                    forKey: Keys.savedBrightness
                ) != nil

            let hasSavedVolume =
                defaults.object(
                    forKey: Keys.savedVolume
                ) != nil

            if hasSavedBrightness {
                if snapshot.brightness != brightness {
                    do {
                        try await driver.setBrightness(
                            brightness
                        )
                    } catch {
                        // Keep the persisted value authoritative and retry
                        // on the next automatic refresh.
                        statusMessage =
                            error.localizedDescription
                    }
                }
            } else if let value = snapshot.brightness {
                brightness = Self.clampPercent(value)
                persist(
                    brightness,
                    forKey: Keys.savedBrightness
                )
            }

            if hasSavedVolume {
                if snapshot.volume != volume {
                    do {
                        try await driver.setVolume(
                            volume
                        )
                    } catch {
                        // Never replace the saved volume with a transient
                        // DDC value. Retry on the next refresh instead.
                        statusMessage =
                            error.localizedDescription
                    }
                }
            } else if let value = snapshot.volume {
                volume = Self.clampPercent(value)
                persist(
                    volume,
                    forKey: Keys.savedVolume
                )
            }

            if volume > 0 {
                lastAudibleVolume = volume
                isMuted = false
            }
        } catch {
            isConnected = false
            statusMessage = error.localizedDescription
        }

        updateKeyboardAuthorization()
        LoginItemManager.shared.refresh()
    }

    func userSetBrightness(_ value: Int) {
        brightness = clamp(value)
        persist(
            brightness,
            forKey: Keys.savedBrightness
        )
        scheduleBrightnessWrite()
    }

    func userSetVolume(_ value: Int) {
        volume = clamp(value)
        persist(
            volume,
            forKey: Keys.savedVolume
        )
        if volume > 0 {
            lastAudibleVolume = volume
            isMuted = false
        }
        scheduleVolumeWrite()
    }

    func changeBrightness(by delta: Int) {
        brightness = clamp(brightness + delta)
        persist(
            brightness,
            forKey: Keys.savedBrightness
        )
        scheduleBrightnessWrite()
    }

    func changeVolume(by delta: Int) {
        if isMuted && delta > 0 {
            isMuted = false
            volume = max(lastAudibleVolume, volumeStep)
        } else {
            volume = clamp(volume + delta)
        }

        if volume > 0 {
            lastAudibleVolume = volume
            isMuted = false
        }

        persist(
            volume,
            forKey: Keys.savedVolume
        )
        scheduleVolumeWrite()
    }

    func toggleMute() {
        let targetMuted = !isMuted

        if targetMuted && volume > 0 {
            lastAudibleVolume = volume
        }

        isMuted = targetMuted

        Task {
            do {
                try await driver.setMute(targetMuted)
            } catch {
                // Compatibility fallback for displays that ignore VCP mute.
                if targetMuted {
                    try? await driver.setVolume(0)
                } else {
                    let restore = max(
                        lastAudibleVolume,
                        volumeStep
                    )
                    volume = restore
                    persist(
                        restore,
                        forKey: Keys.savedVolume
                    )
                    try? await driver.setVolume(restore)
                }
            }
        }
    }

    func setAttenuationDB(_ value: Int) {
        let normalized = Self.quantizedDB(value)

        guard normalized != attenuationDB else {
            return
        }

        attenuationDB = normalized
        persist(
            normalized,
            forKey: Keys.attenuationDB
        )

        applyAttenuation()
    }

    func applyAttenuation() {
        if attenuationDB == 0 {
            audio.stop()
            attenuationStatus = nil
            return
        }

        do {
            try audio.start(
                decibels: attenuationDB
            )
            attenuationStatus = nil
        } catch {
            attenuationStatus =
                error.localizedDescription
        }
    }

    func requestKeyboardAccess() {
        MediaKeyMonitor.shared
            .requestAccessibilityIfNeeded()
    }

    func openAccessibilitySettings() {
        guard let url = URL(
            string:
                "x-apple.systempreferences:" +
                "com.apple.preference.security?" +
                "Privacy_Accessibility"
        ) else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    private func scheduleBrightnessWrite() {
        brightnessWriteTask?.cancel()
        let value = brightness

        brightnessWriteTask = Task {
            try? await Task.sleep(
                nanoseconds: 45_000_000
            )
            guard !Task.isCancelled else {
                return
            }

            do {
                try await driver.setBrightness(value)
                statusMessage = "Connected"
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }

    private func scheduleVolumeWrite() {
        volumeWriteTask?.cancel()
        let value = volume

        volumeWriteTask = Task {
            try? await Task.sleep(
                nanoseconds: 45_000_000
            )
            guard !Task.isCancelled else {
                return
            }

            do {
                try await driver.setVolume(value)
                statusMessage = "Connected"
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }

    private func persist(
        _ value: Int,
        forKey key: String
    ) {
        defaults.set(
            value,
            forKey: key
        )

        // Explicitly flush the small settings payload so quitting
        // immediately after a change still preserves the value.
        defaults.synchronize()
    }

    private static func quantizedDB(
        _ value: Int
    ) -> Int {
        let clamped = min(0, max(-60, value))
        let offset = clamped + 60

        return -60 + Int(
            (
                Double(offset) / 3.0
            ).rounded()
        ) * 3
    }

    private static func clampPercent(
        _ value: Int
    ) -> Int {
        min(100, max(0, value))
    }

    private func clamp(_ value: Int) -> Int {
        Self.clampPercent(value)
    }
}
