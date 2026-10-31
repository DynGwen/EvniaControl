import AppKit
import SwiftUI

struct MenuContentView: View {
    @EnvironmentObject private var model: AppModel
    let onOpenOptions: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Divider()

            controlRow(
                icon: "sun.max.fill",
                title: L10n.brightness,
                value: model.brightness,
                isEnabled: model.isConnected && model.brightnessSupported,
                binding: Binding(
                    get: {
                        Double(model.brightness)
                    },
                    set: {
                        model.userSetBrightness(Int($0))
                    }
                )
            )

            controlRow(
                icon: model.isMuted
                    ? "speaker.slash.fill"
                    : "speaker.wave.2.fill",
                title: L10n.volume,
                value: model.volume,
                isEnabled: model.isConnected && model.volumeSupported && !model.isMuted,
                binding: Binding(
                    get: {
                        Double(model.volume)
                    },
                    set: {
                        model.userSetVolume(Int($0))
                    }
                )
            )

            HStack {
                Button {
                    model.toggleMute()
                } label: {
                    Label(
                        model.isMuted
                            ? L10n.unmute
                            : L10n.mute,
                        systemImage: model.isMuted
                            ? "speaker.wave.2"
                            : "speaker.slash"
                    )
                }
                .disabled(!model.isConnected || !model.volumeSupported)
            }

            if !model.keyboardAuthorized {
                Divider()

                VStack(alignment: .leading, spacing: 7) {
                    Label(
                        L10n.keyboardPermissionRequired,
                        systemImage: "keyboard.badge.ellipsis"
                    )
                    .font(.callout.bold())

                    Text(
                        L10n.keyboardPermissionHelp
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    HStack {
                        Button(L10n.requestAccess) {
                            model.requestKeyboardAccess()
                        }

                        Button(L10n.systemSettings) {
                            model.openAccessibilitySettings()
                        }
                    }
                }
            }

            Divider()

            HStack {
                Button(L10n.options) {
                    onOpenOptions()
                }

                Spacer()

                Button(L10n.quit) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(16)
        .frame(width: 340)
        .tahoeWindowSurface()
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "display")
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(model.displayName)
                    .font(.headline)

                Text(model.statusMessage)
                    .font(.caption)
                    .foregroundStyle(
                        model.isConnected
                            ? Color.secondary
                            : Color.red
                    )
                    .lineLimit(2)
            }

            Spacer()

            Circle()
                .fill(
                    model.isConnected
                        ? Color.green
                        : Color.orange
                )
                .frame(width: 9, height: 9)
        }
    }

    private func controlRow(
        icon: String,
        title: String,
        value: Int,
        isEnabled: Bool,
        binding: Binding<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Text("\(value)%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            TahoePillSlider(
                value: binding,
                range: 0...100,
                step: 1,
                isEnabled: isEnabled
            )
            .accessibilityLabel(title)
            .accessibilityValue(L10n.percent(value))
        }
    }
}
