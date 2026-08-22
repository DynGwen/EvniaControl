import SwiftUI

@main
struct EvniaControlApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    @StateObject private var model = AppModel.shared

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environmentObject(model)
        } label: {
            Label(
                "Evnia Control",
                systemImage: model.isConnected
                    ? "display"
                    : "display.trianglebadge.exclamationmark"
            )
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(model)
        }
    }
}
