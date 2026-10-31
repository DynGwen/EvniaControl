import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {
        Task { @MainActor in
            statusItemController = StatusItemController(model: .shared)
            LoginItemManager.shared.ensureEnabled()
            AppModel.shared.start()
            BrightnessFunctionKeys.shared.start()
            MediaKeyMonitor.shared.start()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        let workspaceNotifications =
            NSWorkspace.shared.notificationCenter

        workspaceNotifications.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        workspaceNotifications.addObserver(
            self,
            selector: #selector(screensDidWake),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        BrightnessFunctionKeys.shared.stop()
        MediaKeyMonitor.shared.stop()
        statusItemController?.stop()
        statusItemController = nil
    }

    @objc
    private func screenConfigurationChanged() {
        Task { @MainActor in
            try? await Task.sleep(
                nanoseconds: 700_000_000
            )
            await AppModel.shared.refresh()
        }
    }

    @objc
    private func systemDidWake() {
        Task { @MainActor in
            AppModel.shared.recoverAfterScreenWake()
            MediaKeyMonitor.shared.restartIfNeeded()
            BrightnessFunctionKeys.shared.restartIfNeeded()
        }
    }

    @objc
    private func screensDidWake() {
        Task { @MainActor in
            AppModel.shared.recoverAfterScreenWake()
            MediaKeyMonitor.shared.restartIfNeeded()
            BrightnessFunctionKeys.shared.restartIfNeeded()
        }
    }
}
