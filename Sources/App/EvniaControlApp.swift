import SwiftUI

@main
struct EvniaControlApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    @StateObject private var model = AppModel.shared

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(model)
        }
    }
}
