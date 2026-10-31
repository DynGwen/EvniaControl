import Combine
import SwiftUI

@MainActor
final class ControlPopupState: ObservableObject {
    @Published var kind: DisplayControlKind = .volume
}

/// Brightness and volume share one panel, the existing glass surface and slider.
struct ControlPopupView: View {
    @EnvironmentObject private var model: AppModel
    @ObservedObject var state: ControlPopupState
    @GestureState private var isDragging = false

    let onHover: (Bool) -> Void
    let onDrag: (Bool) -> Void

    private var title: String {
        state.kind == .brightness ? "Brightness" : "Volume"
    }

    private var value: Int {
        state.kind == .brightness ? model.brightness : model.volume
    }

    private var icon: String {
        if state.kind == .brightness { return "sun.max.fill" }
        return model.isMuted || model.volume == 0
            ? "speaker.slash.fill" : "speaker.wave.2.fill"
    }

    private var isEnabled: Bool {
        model.isConnected && (state.kind == .brightness
            ? model.brightnessSupported : model.volumeSupported && !model.isMuted)
    }

    private var sliderBinding: Binding<Double> {
        // Capture the control for this gesture rather than changing the
        // destination of a drag if a different key arrives during it.
        let kind = state.kind
        return Binding(
            get: { Double(kind == .brightness ? model.brightness : model.volume) },
            set: { value in
                if kind == .brightness { model.userSetBrightness(Int(value)) }
                else { model.userSetVolume(Int(value)) }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).frame(width: 20)
                Text(title).font(.system(size: 13, weight: .medium))
                Spacer()
                Text("\(value)%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            TahoePillSlider(
                value: sliderBinding,
                range: 0...100,
                step: 1,
                isEnabled: isEnabled
            )
            .accessibilityLabel("Display \(title.lowercased())")
            .accessibilityValue("\(value) percent")
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isDragging) { _, dragging, _ in dragging = true }
            )
        }
        .padding(16)
        .frame(width: 300)
        .tahoeWindowSurface()
        .onHover(perform: onHover)
        .onChange(of: isDragging) { _, dragging in onDrag(dragging) }
    }
}
