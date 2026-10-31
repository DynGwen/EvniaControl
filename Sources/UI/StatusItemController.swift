import AppKit
import Combine
import SwiftUI

@MainActor
private final class MenuPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
private final class FeedbackPanel: NSPanel {
    // Showing the feedback must never move keyboard focus away from the app
    // the user is working in, including while dragging the slider.
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Owns the real status item so both windows can anchor to its public button
/// geometry, without searching other apps' menu-bar windows or private APIs.
@MainActor
final class StatusItemController: NSObject {
    private let model: AppModel
    private let statusItem: NSStatusItem
    private let menuPanel = MenuPanel(
        contentRect: .zero,
        styleMask: [.borderless, .nonactivatingPanel],
        backing: .buffered,
        defer: false
    )
    private let feedbackPanel = FeedbackPanel(
        contentRect: .zero,
        styleMask: [.borderless, .nonactivatingPanel],
        backing: .buffered,
        defer: false
    )
    private let popupState = ControlPopupState()
    private var pendingControl: DisplayControlKind?
    private var cancellables = Set<AnyCancellable>()
    private var dismissTask: Task<Void, Never>?
    private var layoutTask: Task<Void, Never>?
    private var globalMouseMonitor: Any?
    private var localEventMonitor: Any?
    private var isHovering = false
    private var isDragging = false

    init(model: AppModel) {
        self.model = model
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        statusItem.autosaveName = "EvniaControl.statusItem"
        statusItem.button?.target = self
        statusItem.button?.action = #selector(toggleMenu)
        // One action per press. Mouse-up must not toggle the panel again.
        statusItem.button?.sendAction(on: [.leftMouseDown])
        statusItem.button?.setAccessibilityLabel("Evnia Control")
        updateIcon()

        let panels: [NSPanel] = [menuPanel, feedbackPanel]
        for panel in panels {
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.level = .statusBar
            panel.hidesOnDeactivate = false
            panel.isReleasedWhenClosed = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
            panel.isFloatingPanel = true
        }
        feedbackPanel.becomesKeyOnlyIfNeeded = true
        menuPanel.contentView = NSHostingView(
            rootView: MenuContentView(onOpenOptions: { [weak self] in
                self?.closeMenu()
                OptionsWindowController.shared.show()
            }).environmentObject(model)
        )
        feedbackPanel.contentView = NSHostingView(
            rootView: ControlPopupView(
                state: popupState,
                onHover: { [weak self] hovering in
                    self?.isHovering = hovering
                    self?.scheduleDismissal()
                },
                onDrag: { [weak self] dragging in
                    self?.draggingChanged(dragging)
                }
            ).environmentObject(model)
        )
        bindModel()
        installEventMonitors()
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeApplicationChanged(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    func stop() {
        dismissTask?.cancel()
        layoutTask?.cancel()
        cancellables.removeAll()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        if let globalMouseMonitor { NSEvent.removeMonitor(globalMouseMonitor) }
        if let localEventMonitor { NSEvent.removeMonitor(localEventMonitor) }
        globalMouseMonitor = nil
        localEventMonitor = nil
        closeMenu()
        dismissFeedback()
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    private func bindModel() {
        model.controlFeedback
            // Keep SwiftUI/window work outside the synchronous media-key tap.
            .receive(on: RunLoop.main)
            .sink { [weak self] kind in self?.showControl(kind) }
            .store(in: &cancellables)

        model.$isConnected
            .receive(on: RunLoop.main)
            .sink { [weak self] connected in
                self?.updateIcon()
                if !connected { self?.dismissFeedback() }
            }
            .store(in: &cancellables)

        // The original menu can change height when permission help appears.
        model.objectWillChange
            .sink { [weak self] in self?.scheduleMenuLayout() }
            .store(in: &cancellables)
    }

    private func updateIcon() {
        let name = model.isConnected ? "display" : "display.trianglebadge.exclamationmark"
        let image = NSImage(systemSymbolName: name, accessibilityDescription: "Evnia Control")
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = "Evnia Control"
    }

    @objc private func toggleMenu() {
        // Only this action changes visibility for a status-button press.
        // Losing key-window status during that press does not close/reopen it.
        if menuPanel.isVisible {
            closeMenu()
            return
        }
        dismissFeedback()
        guard position(menuPanel) else { return }
        statusItem.button?.highlight(true)
        menuPanel.makeKeyAndOrderFront(nil)
    }

    private func closeMenu() {
        menuPanel.orderOut(nil)
        statusItem.button?.highlight(false)
    }

    @objc private func activeApplicationChanged(_ notification: Notification) {
        // A nonactivating panel can be open while another app is active.
        // Workspace activation also catches Command-Tab without a mouse click.
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
            as? NSRunningApplication,
            app.processIdentifier != ProcessInfo.processInfo.processIdentifier
        else { return }
        closeMenu()
        dismissFeedback()
    }

    private func showControl(_ kind: DisplayControlKind) {
        // Both live values already appear in the main menu. Startup, polling
        // and wake do not send feedback events.
        let supported = kind == .brightness ? model.brightnessSupported : model.volumeSupported
        guard model.isConnected, supported, !menuPanel.isVisible else { return }
        if isDragging && kind != popupState.kind {
            pendingControl = kind
            return
        }
        pendingControl = nil
        if popupState.kind != kind { popupState.kind = kind }
        guard position(feedbackPanel) else { return }
        feedbackPanel.orderFrontRegardless()
        scheduleDismissal()
    }

    private func draggingChanged(_ dragging: Bool) {
        isDragging = dragging
        if !dragging, let pendingControl {
            self.pendingControl = nil
            showControl(pendingControl)
        } else {
            scheduleDismissal()
        }
    }

    private func scheduleDismissal() {
        dismissTask?.cancel()
        guard feedbackPanel.isVisible, !isHovering, !isDragging else { return }
        dismissTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(nanoseconds: 2_000_000_000) }
            catch { return }
            guard let self, !Task.isCancelled,
                  !self.isHovering, !self.isDragging else { return }
            self.dismissFeedback()
        }
    }

    private func dismissFeedback() {
        dismissTask?.cancel()
        dismissTask = nil
        feedbackPanel.orderOut(nil)
        pendingControl = nil
        isHovering = false
        isDragging = false
    }

    private func scheduleMenuLayout() {
        guard menuPanel.isVisible else { return }
        layoutTask?.cancel()
        layoutTask = Task { @MainActor [weak self] in
            // Allow SwiftUI to update its intrinsic size before fitting.
            do { try await Task.sleep(nanoseconds: 30_000_000) }
            catch { return }
            guard let self, self.menuPanel.isVisible else { return }
            _ = self.position(self.menuPanel)
        }
    }

    @discardableResult
    private func position(_ panel: NSPanel) -> Bool {
        guard let button = statusItem.button, let buttonWindow = button.window,
              buttonWindow.isVisible, let screen = buttonWindow.screen,
              let content = panel.contentView else { return false }
        content.layoutSubtreeIfNeeded()
        let size = content.fittingSize
        guard size.width > 0, size.height > 0 else { return false }

        let anchor = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let bounds = screen.visibleFrame.insetBy(dx: 8, dy: 8)
        let x = min(max(anchor.midX - size.width / 2, bounds.minX), bounds.maxX - size.width)
        let y = max(bounds.minY, anchor.minY - 8 - size.height)
        panel.setFrame(NSRect(origin: NSPoint(x: x, y: y), size: size), display: true)
        return true
    }

    private func installEventMonitors() {
        // Mouse monitoring does not request keyboard/accessibility permission.
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] event in
            // AppKit calls event monitors on main. Handle the event now so an
            // outside click cannot enqueue a dismissal after the next press.
            MainActor.assumeIsolated {
                guard let self, !self.isStatusButtonPress(event) else { return }
                self.closeMenu()
                self.dismissFeedback()
            }
        }
        localEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown, .keyDown]
        ) { [weak self] event in
            // NSEvent is explicitly non-Sendable in recent SDKs. Only the
            // Boolean decision leaves assumeIsolated; the original event stays
            // in AppKit's callback. AppKit dispatches local monitors on main.
            let consume: Bool = MainActor.assumeIsolated {
                self?.handleLocalEvent(event) ?? false
            }
            return consume ? nil : event
        }
    }

    private func handleLocalEvent(_ event: NSEvent) -> Bool {
        if event.type == .keyDown {
            if event.keyCode == 53, menuPanel.isVisible || feedbackPanel.isVisible {
                closeMenu()
                dismissFeedback()
                return true
            }
            return false
        }
        // Both monitors leave the icon press to the button's single action.
        if isStatusButtonPress(event) { return false }
        if event.window !== menuPanel { closeMenu() }
        if event.window !== feedbackPanel { dismissFeedback() }
        return false
    }

    private func isStatusButtonPress(_ event: NSEvent) -> Bool {
        guard event.type == .leftMouseDown,
              let button = statusItem.button, let window = button.window,
              window.isVisible else { return false }
        let buttonFrame = window.convertToScreen(button.convert(button.bounds, to: nil))
        // Windowless/global mouse events already use screen coordinates.
        let point = event.window?.convertToScreen(
            NSRect(origin: event.locationInWindow, size: .zero)
        ).origin ?? event.locationInWindow
        return buttonFrame.contains(point)
    }
}
