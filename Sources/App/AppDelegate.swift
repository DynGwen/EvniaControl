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

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func screenConfigurationChanged() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            await AppModel.shared.refresh()
        }
    }

    @objc private func systemDidWake() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await AppModel.shared.refresh()
            MediaKeyMonitor.shared.restartIfNeeded()
        }
    }
}
