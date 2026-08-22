import AppKit
import ApplicationServices
import CoreGraphics

@MainActor
final class MediaKeyMonitor: NSObject {
    static let shared = MediaKeyMonitor()

    private enum MediaKey: Int {
        case volumeUp = 0
        case volumeDown = 1
        case brightnessUp = 2
        case brightnessDown = 3
        case mute = 7
    }

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var permissionTimer: Timer?

    private override init() {
        super.init()
    }

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

    func restartIfNeeded() {
        stopTap()
        installTapIfPossible()
    }

    @objc
    private func permissionTimerFired(
        _ timer: Timer
    ) {
        _ = timer
        installTapIfPossible()
        AppModel.shared.updateKeyboardAuthorization()
    }

    private func installTapIfPossible() {
        guard eventTap == nil,
              AXIsProcessTrusted()
        else {
            return
        }

        let systemDefined = CGEventType(rawValue: 14)!
        let mask = CGEventMask(
            1 << systemDefined.rawValue
        )

        let refcon = Unmanaged.passUnretained(self)
            .toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: {
                proxy,
                type,
                event,
                refcon
            in
                _ = proxy

                guard let refcon else {
                    return Unmanaged.passUnretained(event)
                }

                var result: Unmanaged<CGEvent>?

                // The source is attached to CFRunLoopGetMain() below.
                // The closure captures no Swift object.
                MainActor.assumeIsolated {
                    let monitor =
                        Unmanaged<MediaKeyMonitor>
                            .fromOpaque(refcon)
                            .takeUnretainedValue()

                    result = monitor.handle(
                        type: type,
                        event: event
                    )
                }

                return result
            },
            userInfo: refcon
        ) else {
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            tap,
            0
        )

        if let runLoopSource {
            CFRunLoopAddSource(
                CFRunLoopGetMain(),
                runLoopSource,
                .commonModes
            )
        }

        CGEvent.tapEnable(
            tap: tap,
            enable: true
        )
    }

    private func stopTap() {
        if let eventTap {
            CGEvent.tapEnable(
                tap: eventTap,
                enable: false
            )
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(
                CFRunLoopGetMain(),
                runLoopSource,
                .commonModes
            )
        }

        eventTap = nil
        runLoopSource = nil
    }

    private func handle(
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout
            || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(
                    tap: eventTap,
                    enable: true
                )
            }

            return Unmanaged.passUnretained(event)
        }

        guard let nsEvent = NSEvent(cgEvent: event),
              nsEvent.type == .systemDefined,
              nsEvent.subtype.rawValue == 8
        else {
            return Unmanaged.passUnretained(event)
        }

        let data = nsEvent.data1
        let keyCode = (data & 0xFFFF0000) >> 16
        let keyFlags = data & 0x0000FFFF
        let keyState = (keyFlags & 0xFF00) >> 8
        let isKeyDown = keyState == 0x0A

        guard let mediaKey = MediaKey(
            rawValue: keyCode
        )
        else {
            return Unmanaged.passUnretained(event)
        }

        let appModel = AppModel.shared
        let shouldCapture =
            appModel.isConnected
            && appModel.keyboardControlEnabled

        guard shouldCapture else {
            return Unmanaged.passUnretained(event)
        }

        if isKeyDown {
            let fine =
                event.flags.contains(.maskShift)
                && event.flags.contains(.maskAlternate)

            switch mediaKey {
            case .brightnessUp:
                appModel.changeBrightness(
                    by: fine
                        ? 1
                        : appModel.brightnessStep
                )

            case .brightnessDown:
                appModel.changeBrightness(
                    by: fine
                        ? -1
                        : -appModel.brightnessStep
                )

            case .volumeUp:
                appModel.changeVolume(
                    by: fine
                        ? 1
                        : appModel.volumeStep
                )

            case .volumeDown:
                appModel.changeVolume(
                    by: fine
                        ? -1
                        : -appModel.volumeStep
                )

            case .mute:
                appModel.toggleMute()
            }
        }

        return nil
    }

    func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else {
            return
        }

        let options = [
            "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary

        _ = AXIsProcessTrustedWithOptions(options)
    }
}
