/// One brightness action can arrive as a media event, a Magic Keyboard sun
/// key (144/145), or an ordinary F1/F2 key. Keep their direction/step shared.
enum BrightnessKey: UInt32, CaseIterable, Sendable {
    case decrease = 1
    case increase = 2

    static let step = 5

    var keyCode: Int { self == .decrease ? 122 : 120 }
    var nativeKeyCode: Int { self == .decrease ? 145 : 144 }
    var delta: Int { self == .decrease ? -Self.step : Self.step }

    /// Only ordinary F1/F2 are registered with Carbon. Native sun key codes
    /// stay with the event tap, even when F1/F2 registrations succeed.
    static func matchingFunctionKey(keyCode: Int, modifiers: KeyboardEventRouter.Modifiers) -> Self? {
        guard modifiers.isEmpty else { return nil }
        return allCases.first { $0.keyCode == keyCode }
    }

    static func matchingKeyEvent(keyCode: Int, modifiers: KeyboardEventRouter.Modifiers) -> Self? {
        guard modifiers.isEmpty else { return nil }
        return allCases.first { $0.keyCode == keyCode || $0.nativeKeyCode == keyCode }
    }
}
