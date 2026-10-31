import SwiftUI

struct SettingsView: View {
    var body: some View {
        Text(L10n.useOptions)
            .padding(30)
            .frame(width: 360, height: 120)
            .tahoeWindowSurface()
    }
}
