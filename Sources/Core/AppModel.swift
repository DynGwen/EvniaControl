import AppKit
import ApplicationServices
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    // Explicit user-feedback events avoid showing a popup during startup,
    // automatic DDC refresh, or wake recovery. Send after updating the values.
    let controlFeedback = PassthroughSubject<DisplayControlKind, Never>()

    @Published private(set) var isConnected = false
    @Published private(set) var displayName = "Evnia"
    @Published private(set) var statusMessage = L10n.searchingForDisplay
    @Published private(set) var brightnessSupported = false
    @Published private(set) var volumeSupported = false

    @Published var brightness: Int
    @Published var volume: Int
    @Published private(set) var isMuted = false
    @Published private(set) var keyboardAuthorized = false

    @Published private(set) var attenuationDB: Int
    @Published private(set) var attenuationStatus: String?

    let volumeStep = 5

    private enum Keys {
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

        let restoredMuted = storedDefaults.object(
            forKey: Keys.savedMuted
        ) as? Bool ?? false

        brightness = restoredBrightness
        volume = restoredMuted
            ? 0
            : restoredVolume

        // Keyboard control is permanent. An old saved opt-out must not
        // disable it, and legacy/custom step values must not override 5%.
        for key in ["keyboardControlEnabled", "brightnessStep", "volumeStep"] {
            storedDefaults.removeObject(forKey: key)
        }

        attenuationDB = Self.quantizedDB(
            storedDefaults.object(
                forKey: Keys.attenuationDB
            ) as? Int ?? 0
        )

        isMuted = restoredMuted

        // All required stored properties are initialized above.
        lastAudibleVolume = restoredVolume > 0
            ? restoredVolume
            : 50
    }

    private var connectedStatusMessage: String {
        if !brightnessSupported { return L10n.brightnessUnavailable }
        if !volumeSupported { return L10n.volumeUnavailable }
        return L10n.connected
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
        let authorized = AXIsProcessTrusted()
        if keyboardAuthorized != authorized { keyboardAuthorized = authorized }
    }

    func refresh() async {
        do {
            let snapshot = try await driver.refresh()

            displayName = snapshot.display.name
            brightnessSupported = snapshot.brightness != nil
            volumeSupported = snapshot.volume != nil
            isConnected = true
            statusMessage = connectedStatusMessage

            let hasSavedBrightness =
                defaults.object(
                    forKey: Keys.savedBrightness
                ) != nil

            let hasSavedVolume =
                defaults.object(
                    forKey: Keys.savedVolume
                ) != nil

            if brightnessSupported && hasSavedBrightness {
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

            if volumeSupported && isMuted {
                // Mute is authoritative until the user explicitly
                // chooses Unmute. Keep the public/UI value at zero.
                volume = 0

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
            } else if volumeSupported && hasSavedVolume {
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
            brightnessSupported = false
            volumeSupported = false
            statusMessage = error.localizedDescription
        }

        updateKeyboardAuthorization()
        LoginItemManager.shared.refresh()
    }

    func userSetBrightness(_ value: Int) {
        guard isConnected && brightnessSupported else { return }
        let previousBrightness = brightness
        brightness = clamp(value)
        persist(
            brightness,
            forKey: Keys.savedBrightness
        )
        scheduleBrightnessWrite()
        if brightness != previousBrightness {
            controlFeedback.send(.brightness)
        }
    }

    func userSetVolume(_ value: Int) {
        guard isConnected && volumeSupported else { return }
        guard !isMuted else {
            volumeWriteTask?.cancel()
            volume = 0
            return
        }

        let previousVolume = volume
        volume = clamp(value)
        persist(
            volume,
            forKey: Keys.savedVolume
        )

        if volume > 0 {
            lastAudibleVolume = volume
        }

        scheduleVolumeWrite()
        if volume != previousVolume {
            controlFeedback.send(.volume)
        }
    }

    func changeBrightness(by delta: Int) {
        guard isConnected && brightnessSupported else { return }
        let previousBrightness = brightness
        brightness = clamp(brightness + delta)
        persist(
            brightness,
            forKey: Keys.savedBrightness
        )
        scheduleBrightnessWrite()
        if brightness != previousBrightness {
            controlFeedback.send(.brightness)
        }
    }

    func changeVolume(by delta: Int) {
        guard isConnected && volumeSupported else { return }
        guard !isMuted else {
            volumeWriteTask?.cancel()
            volume = 0
            return
        }

        let previousVolume = volume
        volume = clamp(volume + delta)

        if volume > 0 {
            lastAudibleVolume = volume
        }

        persist(
            volume,
            forKey: Keys.savedVolume
        )

        scheduleVolumeWrite()
        if volume != previousVolume {
            controlFeedback.send(.volume)
        }
    }

    func toggleMute() {
        guard isConnected && volumeSupported else { return }
        let targetMuted = !isMuted

        if targetMuted {
            if volume > 0 {
                lastAudibleVolume = volume
                persist(
                    volume,
                    forKey: Keys.savedVolume
                )
            }

            // Prevent a delayed non-zero volume write from racing with
            // the mute command.
            volumeWriteTask?.cancel()
            volumeWriteTask = nil

            volume = 0
            isMuted = true
            persistMuteState()
            controlFeedback.send(.volume)

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
            lastAudibleVolume,
            volumeStep
        )

        volume = clamp(restore)
        lastAudibleVolume = volume
        persist(
            volume,
            forKey: Keys.savedVolume
        )

        controlFeedback.send(.volume)

        Task {
            // Clear hardware mute if the display supports it, then
            // restore the desired volume in all cases.
            try? await driver.setMute(false)

            do {
                try await driver.setVolume(volume)
                statusMessage = connectedStatusMessage
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
            // Let Core Audio rebuild its device list before touching the tap.
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

            // Tear down the old Core Audio tap only after wake.
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
                statusMessage = connectedStatusMessage
            } catch is CancellationError {
                return
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
                statusMessage = connectedStatusMessage
            } catch is CancellationError {
                return
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
