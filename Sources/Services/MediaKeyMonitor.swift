import AppKit
import ApplicationServices
import CoreGraphics

@MainActor
final class MediaKeyMonitor: NSObject {
    static let shared = MediaKeyMonitor()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var permissionTimer: Timer?
    private var router = KeyboardEventRouter()
    private var primaryIsHID = false
    private var nativeBrightnessTap: CFMachPort?
    private var nativeBrightnessSource: CFRunLoopSource?

    private override init() { super.init() }

    func start() {
        requestAccessibilityIfNeeded()
        installTapIfPossible()
        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(
            timeInterval: 3,
            target: self,
            selector: #selector(permissionTimerFired(_:)),
            userInfo: nil,
            repeats: true
        )
    }

    func stop() {
        permissionTimer?.invalidate()
        permissionTimer = nil
        stopTap()
    }

    func restartIfNeeded() {
        stopTap()
        installTapIfPossible()
    }

    @objc private func permissionTimerFired(_ timer: Timer) {
        if !AXIsProcessTrusted(), eventTap != nil { stopTap() }
        installTapIfPossible()
        AppModel.shared.updateKeyboardAuthorization()
    }

    private func installTapIfPossible() {
        guard AXIsProcessTrusted() else { return }
        if let eventTap {
            if CFMachPortIsValid(eventTap) {
                if !CGEvent.tapIsEnabled(tap: eventTap) {
                    CGEvent.tapEnable(tap: eventTap, enable: true)
                }
                installNativeBrightnessTapIfPossible()
                return
            }
            stopTap()
        }

        // NX_SYSDEFINED (14) carries the actual sun and volume keys.
        // KeyDown/Up also carry Magic Keyboard sun codes 144/145 and ordinary F1/F2.
        let eventTypes = [UInt32(14), CGEventType.keyDown.rawValue, CGEventType.keyUp.rawValue]
        let mask = eventTypes.reduce(CGEventMask(0)) {
            $0 | (CGEventMask(1) << $1)
        }
        // Prefer the HID entry point so brightness keys are seen before
        // system routing consumes them. Keep this working volume/F1/F2 route.
        let locations: [CGEventTapLocation] = [.cghidEventTap, .cgSessionEventTap]
        for location in locations {
            guard let tap = createTap(at: location, mask: mask) else { continue }
            guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
                CFMachPortInvalidate(tap)
                continue
            }
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            guard CGEvent.tapIsEnabled(tap: tap) else {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
                CFMachPortInvalidate(tap)
                continue
            }
            eventTap = tap
            runLoopSource = source
            primaryIsHID = location == .cghidEventTap
            installNativeBrightnessTapIfPossible()
            return
        }
    }

    private func createTap(at location: CGEventTapLocation, mask: CGEventMask) -> CFMachPort? {
        CGEvent.tapCreate(
            tap: location,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                // This source is installed exclusively on the main run loop.
                // Only a Sendable Bool leaves the actor assertion.
                let consume: Bool = MainActor.assumeIsolated {
                    Unmanaged<MediaKeyMonitor>.fromOpaque(refcon)
                        .takeUnretainedValue().handle(type: type, event: event)
                }
                return consume ? nil : Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
    }

    private func installNativeBrightnessTapIfPossible() {
        // Magic Keyboard sun events may appear only after WindowServer has
        // translated the HID input. A primary session tap already covers them.
        guard primaryIsHID else { return }
        if let nativeBrightnessTap {
            if CFMachPortIsValid(nativeBrightnessTap) {
                CGEvent.tapEnable(tap: nativeBrightnessTap, enable: true)
                return
            }
            stopNativeBrightnessTap()
        }
        let types = [UInt32(14), CGEventType.keyDown.rawValue, CGEventType.keyUp.rawValue]
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1) }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let consume: Bool = MainActor.assumeIsolated {
                    Unmanaged<MediaKeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
                        .handleNativeBrightness(type: type, event: event)
                }
                return consume ? nil : Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return }
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            return
        }
        nativeBrightnessTap = tap
        nativeBrightnessSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func handleNativeBrightness(type: CGEventType, event: CGEvent) -> Bool {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let nativeBrightnessTap {
                CGEvent.tapEnable(tap: nativeBrightnessTap, enable: true)
            }
            return false
        }
        if type == .keyDown || type == .keyUp {
            let code = Int(event.getIntegerValueField(.keyboardEventKeycode))
            guard BrightnessKey.allCases.contains(where: { $0.nativeKeyCode == code }) else { return false }
        } else {
            guard let nsEvent = NSEvent(cgEvent: event), nsEvent.type == .systemDefined,
                  nsEvent.subtype.rawValue == 8 else { return false }
            let code = (nsEvent.data1 >> 16) & 0xFFFF
            guard code == 2 || code == 3 else { return false }
        }
        // Volume, mute, ordinary F1/F2 and other keys never reach this route.
        // An event consumed by the primary HID tap is not forwarded here.
        return handle(type: type, event: event)
    }

    private func stopNativeBrightnessTap() {
        if let nativeBrightnessTap {
            CGEvent.tapEnable(tap: nativeBrightnessTap, enable: false)
            CFMachPortInvalidate(nativeBrightnessTap)
        }
        if let nativeBrightnessSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), nativeBrightnessSource, .commonModes)
        }
        nativeBrightnessTap = nil
        nativeBrightnessSource = nil
    }

    private func stopTap() {
        stopNativeBrightnessTap()
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        router = KeyboardEventRouter()
        primaryIsHID = false
    }

    private func handle(type: CGEventType, event: CGEvent) -> Bool {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return false
        }

        let model = AppModel.shared
        let configuration = KeyboardEventRouter.Configuration(
            enabled: model.isConnected,
            brightnessAvailable: model.brightnessSupported,
            volumeAvailable: model.volumeSupported,
            volumeStep: model.volumeStep
        )
        var modifiers: KeyboardEventRouter.Modifiers = []
        if event.flags.contains(.maskShift) { modifiers.insert(.shift) }
        if event.flags.contains(.maskAlternate) { modifiers.insert(.option) }
        if event.flags.contains(.maskControl) { modifiers.insert(.control) }
        if event.flags.contains(.maskCommand) { modifiers.insert(.command) }

        let decision: KeyboardEventRouter.Decision
        if type == .keyDown || type == .keyUp {
            let code = Int(event.getIntegerValueField(.keyboardEventKeycode))
            // A successfully registered system hotkey must reach Carbon.
            // Never consume it in this tap as well (which would block/double it).
            if BrightnessFunctionKeys.shared.ownsKey(code: code, modifiers: modifiers) {
                if type == .keyUp {
                    _ = router.keyEvent(code: code, isDown: false, modifiers: modifiers, configuration: configuration)
                }
                return false
            }
            decision = router.keyEvent(
                code: code,
                isDown: type == .keyDown,
                modifiers: modifiers,
                configuration: configuration
            )
        } else if let nsEvent = NSEvent(cgEvent: event),
                  nsEvent.type == .systemDefined, nsEvent.subtype.rawValue == 8 {
            decision = router.mediaEvent(
                data: nsEvent.data1,
                modifiers: modifiers,
                configuration: configuration
            )
        } else {
            return false
        }

        switch decision.action {
        case let .brightness(delta): model.changeBrightness(by: delta)
        case let .volume(delta): model.changeVolume(by: delta)
        case .toggleMute: model.toggleMute()
        case nil: break
        }
        return decision.capturesEvent
    }

    func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        _ = AXIsProcessTrustedWithOptions(
            ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        )
    }
}
