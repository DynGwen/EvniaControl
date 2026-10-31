// Standard-library-only checks compiled with the production routing sources.
private struct KeyboardCheckFailure: Error, CustomStringConvertible {
    let description: String
}

private func expectEqual<T: Equatable>(
    _ actual: T, _ expected: T,
    file: StaticString = #filePath, line: UInt = #line
) throws {
    guard actual == expected else {
        throw KeyboardCheckFailure(description: "\(file):\(line): expected \(expected), got \(actual)")
    }
}

private struct KeyboardRoutingChecks {
    private typealias Router = KeyboardEventRouter
    private var connected: Router.Configuration {
        .init(enabled: true, brightnessAvailable: true, volumeAvailable: true)
    }

    private func media(_ code: Int, down: Bool = true) -> Int {
        (code << 16) | ((down ? 0x0A : 0x0B) << 8)
    }

    func sunKeysAlwaysUseFivePercent() throws {
        let modifiers: [Router.Modifiers] = [[], [.option, .shift]]
        for flags in modifiers {
            var router = Router()
            try expectEqual(router.mediaEvent(data: media(2), modifiers: flags, configuration: connected).action, .brightness(5))
            try expectEqual(router.mediaEvent(data: media(3), modifiers: flags, configuration: connected).action, .brightness(-5))
        }
    }

    func bareFunctionKeysMatchNativeSunKeys() throws {
        var router = Router()
        try expectEqual(router.keyEvent(code: 122, isDown: true, modifiers: [], configuration: connected).action, .brightness(-5))
        try expectEqual(router.keyEvent(code: 120, isDown: true, modifiers: [], configuration: connected).action, .brightness(5))
    }

    func magicKeyboardSunCodesUseFivePercent() throws {
        // Reported Magic Keyboard codes: 145 down, 144 up. These are not F1/F2
        // and must reach the router even when Carbon owns ordinary F1/F2.
        for (code, delta) in [(145, -5), (144, 5)] {
            var router = Router()
            let pressed = router.keyEvent(code: code, isDown: true, modifiers: [], configuration: connected)
            try expectEqual(pressed.capturesEvent, true)
            try expectEqual(pressed.action, .brightness(delta))
            try expectEqual(BrightnessKey.matchingFunctionKey(keyCode: code, modifiers: []), nil)
            try expectEqual(BrightnessKey.matchingKeyEvent(keyCode: code, modifiers: [])?.delta, delta)
            try expectEqual(router.keyEvent(code: code, isDown: false, modifiers: [], configuration: connected), .consume)
        }
    }

    func magicKeyboardRepeatAndReleaseAfterDisconnect() throws {
        var router = Router()
        var disconnected = connected
        disconnected.enabled = false
        for _ in 0..<4 {
            try expectEqual(router.keyEvent(code: 144, isDown: true, modifiers: [], configuration: connected).action, .brightness(5))
        }
        try expectEqual(router.keyEvent(code: 144, isDown: true, modifiers: [], configuration: disconnected), .consume)
        try expectEqual(router.keyEvent(code: 144, isDown: false, modifiers: .shift, configuration: disconnected), .consume)
        try expectEqual(router.keyEvent(code: 144, isDown: false, modifiers: [], configuration: disconnected), .pass)
    }

    func oneStepPerRepeatedEvent() throws {
        var router = Router()
        for _ in 0..<4 {
            try expectEqual(router.keyEvent(code: 120, isDown: true, modifiers: [], configuration: connected).action, .brightness(5))
            try expectEqual(router.mediaEvent(data: media(2) | 1, modifiers: [], configuration: connected).action, .brightness(5))
        }
    }

    func otherShortcutsPassThrough() throws {
        let modifiers: [Router.Modifiers] = [.command, .control, .shift, .option, [.option, .shift], [.control, .command], [.control, .command, .shift]]
        for flags in modifiers {
            for code in [122, 120, 144, 145, 126, 125] {
                var router = Router()
                try expectEqual(router.keyEvent(code: code, isDown: true, modifiers: flags, configuration: connected), .pass)
                try expectEqual(BrightnessKey.matchingFunctionKey(keyCode: code, modifiers: flags), nil)
            }
        }
        var router = Router()
        for code in [126, 125, 123, 124, 99] {
            try expectEqual(router.keyEvent(code: code, isDown: true, modifiers: [], configuration: connected), .pass)
        }
    }

    func volumeStepsArePreserved() throws {
        var router = Router()
        try expectEqual(router.mediaEvent(data: media(0), modifiers: [], configuration: connected).action, .volume(5))
        try expectEqual(router.mediaEvent(data: media(1), modifiers: [], configuration: connected).action, .volume(-5))
        try expectEqual(router.mediaEvent(data: media(0), modifiers: [.option, .shift], configuration: connected).action, .volume(1))
        try expectEqual(router.mediaEvent(data: media(1), modifiers: [.option, .shift], configuration: connected).action, .volume(-1))
    }

    func unsupportedBrightnessLeavesVolumeWorking() throws {
        var router = Router()
        var configuration = connected
        configuration.brightnessAvailable = false
        for code in [2, 3] {
            try expectEqual(router.mediaEvent(data: media(code), modifiers: [], configuration: configuration), .pass)
        }
        for code in [122, 120, 144, 145] {
            try expectEqual(router.keyEvent(code: code, isDown: true, modifiers: [], configuration: configuration), .pass)
        }
        try expectEqual(router.mediaEvent(data: media(0), modifiers: [], configuration: configuration).action, .volume(5))
    }

    func unsupportedVolumeLeavesBrightnessWorking() throws {
        var router = Router()
        var configuration = connected
        configuration.volumeAvailable = false
        for code in [0, 1, 7] {
            try expectEqual(router.mediaEvent(data: media(code), modifiers: [], configuration: configuration), .pass)
        }
        try expectEqual(router.mediaEvent(data: media(2), modifiers: [], configuration: configuration).action, .brightness(5))
    }

    func capturedMediaReleaseAfterDisconnect() throws {
        var router = Router()
        var disconnected = connected
        disconnected.enabled = false
        try expectEqual(router.mediaEvent(data: media(2), modifiers: [], configuration: connected).action, .brightness(5))
        try expectEqual(router.mediaEvent(data: media(2), modifiers: [], configuration: disconnected), .consume)
        try expectEqual(router.mediaEvent(data: media(2, down: false), modifiers: [], configuration: disconnected), .consume)
        try expectEqual(router.mediaEvent(data: media(2, down: false), modifiers: [], configuration: disconnected), .pass)
    }

    func functionKeyReleaseAfterModifierChange() throws {
        var router = Router()
        var disconnected = connected
        disconnected.enabled = false
        try expectEqual(router.keyEvent(code: 120, isDown: true, modifiers: [], configuration: connected).action, .brightness(5))
        try expectEqual(router.keyEvent(code: 120, isDown: false, modifiers: .shift, configuration: disconnected), .consume)
        try expectEqual(router.keyEvent(code: 120, isDown: false, modifiers: [], configuration: disconnected), .pass)
    }

    func holdingMuteTogglesOnlyOnce() throws {
        var router = Router()
        try expectEqual(router.mediaEvent(data: media(7), modifiers: [], configuration: connected).action, .toggleMute)
        try expectEqual(router.mediaEvent(data: media(7) | 1, modifiers: [], configuration: connected), .consume)
        try expectEqual(router.mediaEvent(data: media(7, down: false), modifiers: [], configuration: connected), .consume)
        try expectEqual(router.mediaEvent(data: media(7), modifiers: [], configuration: connected).action, .toggleMute)
    }

    func disabledAndUnknownInputsPassThrough() throws {
        var router = Router()
        var configuration = connected
        configuration.enabled = false
        for code in [0, 1, 2, 3, 7] {
            try expectEqual(router.mediaEvent(data: media(code), modifiers: [], configuration: configuration), .pass)
        }
        try expectEqual(router.keyEvent(code: 120, isDown: true, modifiers: [], configuration: configuration), .pass)
        try expectEqual(router.mediaEvent(data: media(16), modifiers: [], configuration: connected), .pass)
        try expectEqual(router.mediaEvent(data: (2 << 16) | (0x0C << 8), modifiers: [], configuration: connected), .pass)
    }

    func onlyTwoFunctionKeysAreRegistered() throws {
        let keys = BrightnessKey.allCases
        try expectEqual(keys.count, 2)
        try expectEqual(Set(keys.map(\.keyCode)), Set([122, 120]))
        try expectEqual(Set(keys.map(\.delta)), Set([-5, 5]))
        try expectEqual(Set(keys.map(\.rawValue)).count, 2)
        for key in keys {
            var router = Router()
            try expectEqual(BrightnessKey.matchingFunctionKey(keyCode: key.keyCode, modifiers: []), key)
            try expectEqual(router.keyEvent(code: key.keyCode, isDown: true, modifiers: [], configuration: connected).action, .brightness(key.delta))
        }
        try expectEqual(BrightnessKey(rawValue: 999), nil)
    }

    func run() throws {
        let cases: [(String, () throws -> Void)] = [
            ("Sun keys: fixed 5%", sunKeysAlwaysUseFivePercent),
            ("F1/F2: same brightness actions", bareFunctionKeysMatchNativeSunKeys),
            ("Magic Keyboard sun codes: fixed 5%", magicKeyboardSunCodesUseFivePercent),
            ("Magic Keyboard: repeat and disconnect release", magicKeyboardRepeatAndReleaseAfterDisconnect),
            ("Repeats: one action per event", oneStepPerRepeatedEvent),
            ("Other shortcuts: passed through", otherShortcutsPassThrough),
            ("Volume: existing normal/fine steps", volumeStepsArePreserved),
            ("Unavailable brightness: volume preserved", unsupportedBrightnessLeavesVolumeWorking),
            ("Unavailable volume: brightness preserved", unsupportedVolumeLeavesBrightnessWorking),
            ("Media release after disconnect", capturedMediaReleaseAfterDisconnect),
            ("Function-key release after modifier change", functionKeyReleaseAfterModifierChange),
            ("Mute: one toggle per press", holdingMuteTogglesOnlyOnce),
            ("Disabled/unknown inputs: passed through", disabledAndUnknownInputsPassThrough),
            ("Registration: only two sun function keys", onlyTwoFunctionKeysAreRegistered),
        ]
        for (name, runCase) in cases {
            try runCase()
            print("PASS \(name)")
        }
        print("Keyboard routing: \(cases.count) checks passed.")
    }
}

@main
enum KeyboardCheckMain {
    static func main() throws {
        try KeyboardRoutingChecks().run()
    }
}
