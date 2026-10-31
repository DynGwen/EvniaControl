/// Pure routing logic. The AppKit/CGEvent objects never cross actor boundaries.
struct KeyboardEventRouter: Sendable {
    struct Modifiers: OptionSet, Sendable {
        let rawValue: Int
        static let shift = Self(rawValue: 1 << 0)
        static let option = Self(rawValue: 1 << 1)
        static let control = Self(rawValue: 1 << 2)
        static let command = Self(rawValue: 1 << 3)
    }

    struct Configuration: Sendable {
        var enabled: Bool
        var brightnessAvailable: Bool
        var volumeAvailable: Bool
        var volumeStep: Int = 5
    }

    enum Action: Equatable, Sendable {
        case brightness(Int)
        case volume(Int)
        case toggleMute
    }

    struct Decision: Equatable, Sendable {
        let capturesEvent: Bool
        let action: Action?
        static let pass = Self(capturesEvent: false, action: nil)
        static let consume = Self(capturesEvent: true, action: nil)
    }

    private enum MediaKey: Int {
        case volumeUp = 0, volumeDown = 1
        case brightnessUp = 2, brightnessDown = 3
        case mute = 7

        var isBrightness: Bool {
            self == .brightnessUp || self == .brightnessDown
        }
    }

    private var capturedMediaKeys: Set<Int> = []
    private var capturedKeyCodes: Set<Int> = []

    mutating func mediaEvent(
        data: Int,
        modifiers: Modifiers,
        configuration: Configuration
    ) -> Decision {
        let code = (data >> 16) & 0xFFFF
        let state = (data >> 8) & 0xFF
        guard let key = MediaKey(rawValue: code) else { return .pass }

        if state == 0x0B {
            return capturedMediaKeys.remove(code) != nil ? .consume : .pass
        }
        guard state == 0x0A else { return .pass }

        let wasHeld = capturedMediaKeys.contains(code)
        let available = key.isBrightness
            ? configuration.brightnessAvailable : configuration.volumeAvailable
        guard configuration.enabled && available else {
            return wasHeld ? .consume : .pass
        }
        capturedMediaKeys.insert(code)

        let fine = modifiers.contains([.shift, .option])
        let volumeStep = fine ? 1 : max(1, configuration.volumeStep)
        let action: Action?
        switch key {
        case .brightnessUp: action = .brightness(BrightnessKey.step)
        case .brightnessDown: action = .brightness(-BrightnessKey.step)
        case .volumeUp: action = .volume(volumeStep)
        case .volumeDown: action = .volume(-volumeStep)
        // Holding mute must never toggle it back and forth.
        case .mute: action = wasHeld ? nil : .toggleMute
        }
        return Decision(capturesEvent: true, action: action)
    }

    mutating func keyEvent(
        code: Int,
        isDown: Bool,
        modifiers: Modifiers,
        configuration: Configuration
    ) -> Decision {
        guard BrightnessKey.allCases.contains(where: { $0.keyCode == code || $0.nativeKeyCode == code }) else { return .pass }
        if !isDown {
            return capturedKeyCodes.remove(code) != nil ? .consume : .pass
        }

        let wasHeld = capturedKeyCodes.contains(code)
        guard configuration.enabled, configuration.brightnessAvailable,
              let key = BrightnessKey.matchingKeyEvent(keyCode: code, modifiers: modifiers)
        else { return wasHeld ? .consume : .pass }

        capturedKeyCodes.insert(code)
        return Decision(
            capturesEvent: true,
            action: .brightness(key.delta)
        )
    }
}
