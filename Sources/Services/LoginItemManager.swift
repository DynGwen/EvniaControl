import Combine
import Foundation
import ServiceManagement

@MainActor
final class LoginItemManager: ObservableObject {
    static let shared = LoginItemManager()

    @Published private(set) var isEnabled = false
    @Published private(set) var requiresApproval = false
    @Published private(set) var lastError: String?

    private init() {
        refresh()
    }

    func refresh() {
        let status = SMAppService.mainApp.status
        isEnabled = status == .enabled
        requiresApproval = status == .requiresApproval
    }

    func ensureEnabled() {
        refresh()

        guard !isEnabled, !requiresApproval else {
            return
        }

        do {
            try SMAppService.mainApp.register()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }

        refresh()
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }

        refresh()
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
