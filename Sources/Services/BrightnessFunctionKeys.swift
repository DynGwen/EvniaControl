import AppKit
import Carbon
import Combine

/// Receives the same sun keys when macOS emits bare F1/F2 instead of media events.
@MainActor
final class BrightnessFunctionKeys: NSObject {
    static let shared = BrightnessFunctionKeys()
    private let signature: UInt32 = 0x45564E42 // EVNB
    private var handler: EventHandlerRef?
    private var registrations: [UInt32: EventHotKeyRef] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var retryTimer: Timer?
    private var heldID: UInt32?
    private var repeatTask: Task<Void, Never>?
    private var started = false

    private override init() { super.init() }

    func start() {
        guard !started else { return }
        started = true
        AppModel.shared.$isConnected
            .combineLatest(AppModel.shared.$brightnessSupported)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshRegistration() }
            .store(in: &cancellables)
        retryTimer = Timer.scheduledTimer(
            timeInterval: 5, target: self,
            selector: #selector(retryRegistration(_:)), userInfo: nil, repeats: true
        )
        refreshRegistration()
    }

    func stop() {
        started = false
        retryTimer?.invalidate()
        retryTimer = nil
        cancellables.removeAll()
        unregisterAll()
        if let handler { RemoveEventHandler(handler) }
        handler = nil
    }

    func restartIfNeeded() {
        guard started else { return }
        unregisterAll()
        refreshRegistration()
    }

    @objc private func retryRegistration(_ timer: Timer) {
        refreshRegistration()
    }

    func ownsKey(code: Int, modifiers: KeyboardEventRouter.Modifiers) -> Bool {
        guard let key = BrightnessKey.matchingFunctionKey(keyCode: code, modifiers: modifiers) else { return false }
        return registrations[key.rawValue] != nil
    }

    private func installHandler() -> Bool {
        if handler != nil { return true }
        // Registration uses the dispatcher; reception uses the application
        // target, as in the working macOS 27 receiver.
        guard let target = GetApplicationEventTarget() else { return false }
        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased)),
        ]
        let status = InstallEventHandler(
            target,
            { _, event, refcon in
                guard let event, let refcon else { return OSStatus(eventNotHandledErr) }
                var identifier = EventHotKeyID()
                let status = GetEventParameter(
                    event, UInt32(kEventParamDirectObject), UInt32(typeEventHotKeyID),
                    nil, MemoryLayout<EventHotKeyID>.size, nil, &identifier
                )
                let id = identifier.id
                let signature = identifier.signature
                let kind = GetEventKind(event)
                // Carbon dispatches on the app's main event loop. Only numeric
                // values leave this actor assertion, never EventRef/NSEvent.
                return MainActor.assumeIsolated {
                    guard status == noErr else { return status }
                    return Unmanaged<BrightnessFunctionKeys>.fromOpaque(refcon)
                        .takeUnretainedValue().handle(id: id, signature: signature, kind: kind)
                }
            },
            eventTypes.count, &eventTypes,
            Unmanaged.passUnretained(self).toOpaque(), &handler
        )
        return status == noErr && handler != nil
    }

    private func refreshRegistration() {
        guard started else { return }
        let model = AppModel.shared
        guard model.isConnected && model.brightnessSupported else {
            unregisterAll()
            return
        }
        guard installHandler() else { return }
        for key in BrightnessKey.allCases where registrations[key.rawValue] == nil {
            var reference: EventHotKeyRef?
            let status = RegisterEventHotKey(
                UInt32(key.keyCode), 0,
                EventHotKeyID(signature: signature, id: key.rawValue),
                GetEventDispatcherTarget(), 0, &reference
            )
            if status == noErr, let reference {
                registrations[key.rawValue] = reference
            }
            // Refused registrations are retried; the event-tap fallback
            // remains available until registration succeeds.
        }
    }

    private func unregisterAll() {
        cancelRepeat()
        for reference in registrations.values { UnregisterEventHotKey(reference) }
        registrations.removeAll()
    }

    private func handle(id: UInt32, signature: UInt32, kind: UInt32) -> OSStatus {
        guard signature == self.signature, registrations[id] != nil,
              let key = BrightnessKey(rawValue: id) else { return OSStatus(eventNotHandledErr) }
        if kind == UInt32(kEventHotKeyReleased) {
            if heldID == id { cancelRepeat() }
            return noErr
        }
        guard kind == UInt32(kEventHotKeyPressed) else { return OSStatus(eventNotHandledErr) }
        // One bounded task owns repeats until release, disconnect or a limit.
        if heldID == id { return noErr }
        cancelRepeat()
        heldID = id
        guard perform(key) else { return noErr }
        repeatTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(nanoseconds: 450_000_000) }
            catch { return }
            for _ in 0..<100 {
                guard let self, !Task.isCancelled, self.heldID == id else { return }
                guard self.perform(key) else { return }
                do { try await Task.sleep(nanoseconds: 90_000_000) }
                catch { return }
            }
        }
        return noErr
    }

    @discardableResult
    private func perform(_ key: BrightnessKey) -> Bool {
        let model = AppModel.shared
        let before = model.brightness
        model.changeBrightness(by: key.delta)
        return before != model.brightness
    }

    private func cancelRepeat() {
        repeatTask?.cancel()
        repeatTask = nil
        heldID = nil
    }
}
