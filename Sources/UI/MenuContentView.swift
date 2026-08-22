import AppKit
import SwiftUI

struct MenuContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Divider()

            controlRow(
                icon: "sun.max.fill",
                title: "Brightness",
                value: model.brightness,
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
                title: "Volume",
                value: model.volume,
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
                            ? "Unmute"
                            : "Mute",
                        systemImage: model.isMuted
                            ? "speaker.wave.2"
                            : "speaker.slash"
                    )
                }
            }

            if !model.keyboardAuthorized {
                Divider()

                VStack(alignment: .leading, spacing: 7) {
                    Label(
                        "Keyboard permission required",
                        systemImage: "keyboard.badge.ellipsis"
                    )
                    .font(.callout.bold())

                    Text(
                        "Allow Evnia Control in " +
                        "Privacy & Security > Accessibility " +
                        "to use the Magic Keyboard media keys."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    HStack {
                        Button("Request Access") {
                            model.requestKeyboardAccess()
                        }

                        Button("System Settings") {
                            model.openAccessibilitySettings()
                        }
                    }
                }
            }

            Divider()

            HStack {
                Button("Options…") {
                    OptionsWindowController.shared.show()
                }

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(16)
        .frame(width: 340)
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

            Slider(
                value: binding,
                in: 0...100,
                step: 1
            )
            .disabled(!model.isConnected)
        }
    }
}
