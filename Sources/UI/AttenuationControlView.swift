import AppKit
import Combine
import SwiftUI

@MainActor
private final class AttenuationViewModel:
    ObservableObject {
    @Published var value = 0
    @Published var isEnabled = true

    var onChange: ((Int) -> Void)?

    func setValue(
        _ newValue: Int,
        notify: Bool
    ) {
        let quantized = Self.quantize(
            newValue
        )

        value = quantized

        if notify {
            onChange?(quantized)
        }
    }

    func userSetValue(
        _ newValue: Double
    ) {
        setValue(
            Int(newValue.rounded()),
            notify: true
        )
    }

    private static func quantize(
        _ value: Int
    ) -> Int {
        let clamped = min(
            0,
            max(-60, value)
        )
        let offset = clamped + 60

        return -60 + Int(
            (
                Double(offset) / 3.0
            ).rounded()
        ) * 3
    }
}

@MainActor
private struct AttenuationSliderContent:
    View {
    @ObservedObject var model:
        AttenuationViewModel

    private var sliderBinding:
        Binding<Double> {
        Binding(
            get: {
                Double(model.value)
            },
            set: {
                model.userSetValue($0)
            }
        )
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 5
        ) {
            HStack {
                Text("Attenuation")
                    .font(
                        .system(
                            size: 13,
                            weight: .medium
                        )
                    )

                Spacer()

                Text("\(model.value) dB")
                    .font(
                        .system(
                            size: 13,
                            weight: .medium,
                            design: .monospaced
                        )
                    )
            }

            TahoePillSlider(
                value: sliderBinding,
                range: -60...0,
                step: 3,
                isEnabled:
                    model.isEnabled,
                showsGraduations: true,
                graduationCount: 21
            )

            HStack {
                Text("−60 dB")
                Spacer()
                Text("0 dB")
            }
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 2)
    }
}

@MainActor
final class AttenuationControlView:
    NSView {
    static let preferredHeight:
        CGFloat = 92

    var onChange: ((Int) -> Void)? {
        didSet {
            model.onChange = onChange
        }
    }

    private let model =
        AttenuationViewModel()

    private lazy var hostingView =
        NSHostingView(
            rootView:
                AttenuationSliderContent(
                    model: model
                )
        )

    override init(
        frame frameRect: NSRect
    ) {
        super.init(frame: frameRect)

        hostingView
            .translatesAutoresizingMaskIntoConstraints =
                false

        addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(
                equalTo: leadingAnchor
            ),
            hostingView.trailingAnchor.constraint(
                equalTo: trailingAnchor
            ),
            hostingView.topAnchor.constraint(
                equalTo: topAnchor
            ),
            hostingView.bottomAnchor.constraint(
                equalTo: bottomAnchor
            ),
        ])

        model.setValue(
            0,
            notify: false
        )
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError(
            "init(coder:) has not been implemented"
        )
    }

    func setValue(
        _ value: Int,
        notify: Bool
    ) {
        model.setValue(
            value,
            notify: notify
        )
    }

    func setEnabled(
        _ enabled: Bool
    ) {
        model.isEnabled = enabled
    }
}
