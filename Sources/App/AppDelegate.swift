import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {
        Task { @MainActor in
            LoginItemManager.shared.ensureEnabled()
            AppModel.shared.start()
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
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        workspaceNotifications.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        workspaceNotifications.addObserver(
            self,
            selector: #selector(screensDidSleep),
            name: NSWorkspace.screensDidSleepNotification,
            object: nil
        )

        workspaceNotifications.addObserver(
            self,
            selector: #selector(screensDidWake),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
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
    private func systemWillSleep() {
        Task { @MainActor in
            AppModel.shared.prepareForScreenSleep()
        }
    }

    @objc
    private func screensDidSleep() {
        Task { @MainActor in
            AppModel.shared.prepareForScreenSleep()
        }
    }

    @objc
    private func systemDidWake() {
        Task { @MainActor in
            AppModel.shared.recoverAfterScreenWake()
            MediaKeyMonitor.shared.restartIfNeeded()
        }
    }

    @objc
    private func screensDidWake() {
        Task { @MainActor in
            AppModel.shared.recoverAfterScreenWake()
            MediaKeyMonitor.shared.restartIfNeeded()
        }
    }
}
