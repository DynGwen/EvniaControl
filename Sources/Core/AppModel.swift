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
        static let savedMuted =
            "monitorState.muted"
    }

    private let defaults = UserDefaults.standard
    private let driver = M1DDCDriver.shared
    private let audio = AudioController()

    private var brightnessWriteTask: Task<Void, Never>?
    private var volumeWriteTask: Task<Void, Never>?
    private var refreshTimer: Timer?
    private var audioRecoveryTask: Task<Void, Never>?
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

        isMuted = storedDefaults.object(
            forKey: Keys.savedMuted
        ) as? Bool ?? false

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

            if isMuted {
                // Mute is authoritative until the user explicitly
                // chooses Unmute. Never restore a non-zero hardware
                // volume from an automatic refresh while muted.
                do {
                    try await driver.setMute(true)
                } catch {
                    // Some displays do not implement VCP mute reliably.
                    // Volume 0 is the fail-safe mute state.
                }

                do {
                    try await driver.setVolume(0)
                } catch {
                    statusMessage =
                        error.localizedDescription
                }
            } else if hasSavedVolume {
                if snapshot.volume != volume {
                    do {
                        try await driver.setVolume(
                            volume
                        )
                    } catch {
                        // Never replace the saved volume with a transient
                        // DDC value. Retry on the next automatic refresh.
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

            if !isMuted && volume > 0 {
                lastAudibleVolume = volume
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
        }

        guard !isMuted else {
            // While muted, update only the desired volume. It will be
            // applied when the user explicitly unmutes.
            volumeWriteTask?.cancel()
            return
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
        volume = clamp(volume + delta)

        if volume > 0 {
            lastAudibleVolume = volume
        }

        persist(
            volume,
            forKey: Keys.savedVolume
        )

        guard !isMuted else {
            // Media-key volume changes adjust the desired level but
            // cannot implicitly unmute the display.
            volumeWriteTask?.cancel()
            return
        }

        scheduleVolumeWrite()
    }

    func toggleMute() {
        let targetMuted = !isMuted

        if targetMuted {
            if volume > 0 {
                lastAudibleVolume = volume
            }

            // Prevent a delayed non-zero volume write from racing with
            // the mute command.
            volumeWriteTask?.cancel()
            volumeWriteTask = nil

            isMuted = true
            persistMuteState()

            Task {
                // Try the monitor's real mute command first.
                try? await driver.setMute(true)

                // Always force hardware volume to zero as a fail-safe.
                // The desired volume remains stored in `volume`.
                try? await driver.setVolume(0)
            }

            return
        }

        isMuted = false
        persistMuteState()

        let restore = max(
            volume > 0 ? volume : lastAudibleVolume,
            volumeStep
        )

        volume = clamp(restore)
        lastAudibleVolume = volume
        persist(
            volume,
            forKey: Keys.savedVolume
        )

        Task {
            // Clear hardware mute if the display supports it, then
            // restore the desired volume in all cases.
            try? await driver.setMute(false)

            do {
                try await driver.setVolume(volume)
                statusMessage = "Connected"
            } catch {
                statusMessage =
                    error.localizedDescription
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

    func recoverAfterScreenWake() {
        audioRecoveryTask?.cancel()

        audioRecoveryTask = Task { @MainActor in
            // Same initial wake delay used by the working 0.2.7
            // implementation. Let Core Audio rebuild its device list
            // before touching the tap.
            do {
                try await Task.sleep(
                    nanoseconds: 750_000_000
                )
            } catch {
                return
            }

            guard !Task.isCancelled else {
                return
            }

            await AppModel.shared.refresh()

            guard AppModel.shared.attenuationDB < 0 else {
                return
            }

            // Critical change from 1.0.21/1.0.22:
            // tear down the old Core Audio tap only AFTER wake.
            AppModel.shared.audio
                .prepareForWakeRestart()

            var lastError: Error?

            // The display audio endpoint can reappear slightly after the
            // screen itself. Retry the rebuild for a bounded period.
            for attempt in 0..<8 {
                guard !Task.isCancelled else {
                    return
                }

                if attempt > 0 {
                    do {
                        try await Task.sleep(
                            nanoseconds: 750_000_000
                        )
                    } catch {
                        return
                    }
                }

                do {
                    let resumed =
                        try AppModel.shared.audio
                            .resumePreferredOutput(
                                decibels:
                                    AppModel.shared
                                        .attenuationDB
                            )

                    if resumed {
                        AppModel.shared
                            .attenuationStatus = nil
                        return
                    }
                } catch {
                    lastError = error
                }
            }

            // Last resort: rebuild on the current macOS output so the
            // global tap cannot leave the system silent.
            do {
                AppModel.shared.audio
                    .prepareForWakeRestart()

                try AppModel.shared.audio
                    .resumeDefaultOutput(
                        decibels:
                            AppModel.shared
                                .attenuationDB
                    )

                AppModel.shared
                    .attenuationStatus = nil
            } catch {
                AppModel.shared
                    .attenuationStatus =
                        (lastError ?? error)
                            .localizedDescription
            }
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

    private func persistMuteState() {
        defaults.set(
            isMuted,
            forKey: Keys.savedMuted
        )
        defaults.synchronize()
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
