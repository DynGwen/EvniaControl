import AppKit

@MainActor
final class AttenuationControlView: NSView {
    static let preferredHeight: CGFloat = 92

    var onChange: ((Int) -> Void)?

    private let titleLabel = NSTextField(
        labelWithString: "Attenuation"
    )
    private let valueLabel = NSTextField(
        labelWithString: ""
    )
    private let minimumLabel = NSTextField(
        labelWithString: "−60 dB"
    )
    private let maximumLabel = NSTextField(
        labelWithString: "0 dB"
    )

    private let slider = NSSlider(
        value: 0,
        minValue: -60,
        maxValue: 0,
        target: nil,
        action: nil
    )

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        titleLabel.font = .systemFont(
            ofSize: 13,
            weight: .medium
        )

        valueLabel.font =
            .monospacedDigitSystemFont(
                ofSize: 13,
                weight: .medium
            )
        valueLabel.alignment = .right

        minimumLabel.font =
            .systemFont(ofSize: 10)
        minimumLabel.textColor =
            .secondaryLabelColor

        maximumLabel.font =
            .systemFont(ofSize: 10)
        maximumLabel.textColor =
            .secondaryLabelColor
        maximumLabel.alignment = .right

        slider.isContinuous = true
        slider.numberOfTickMarks = 21
        slider.tickMarkPosition = .below
        slider.allowsTickMarkValuesOnly = true
        slider.target = self
        slider.action =
            #selector(sliderChanged(_:))

        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(slider)
        addSubview(minimumLabel)
        addSubview(maximumLabel)

        setValue(0, notify: false)
    }

    required init?(coder: NSCoder) {
        fatalError(
            "init(coder:) has not been implemented"
        )
    }

    override func layout() {
        super.layout()

        // The slider consumes virtually the full width:
        // only 8 pt inset on each side, as in the 0.2.7 example.
        let width = bounds.width

        titleLabel.frame = NSRect(
            x: 8,
            y: 67,
            width: width - 128,
            height: 18
        )

        valueLabel.frame = NSRect(
            x: width - 116,
            y: 67,
            width: 108,
            height: 18
        )

        slider.frame = NSRect(
            x: 8,
            y: 27,
            width: width - 16,
            height: 32
        )

        minimumLabel.frame = NSRect(
            x: 8,
            y: 4,
            width: 100,
            height: 16
        )

        maximumLabel.frame = NSRect(
            x: width - 108,
            y: 4,
            width: 100,
            height: 16
        )
    }

    func setValue(
        _ value: Int,
        notify: Bool
    ) {
        let quantized = quantize(value)

        slider.doubleValue =
            Double(quantized)

        valueLabel.stringValue =
            "\(quantized) dB"

        if notify {
            onChange?(quantized)
        }
    }

    func setEnabled(_ enabled: Bool) {
        slider.isEnabled = enabled

        titleLabel.textColor = enabled
            ? .labelColor
            : .disabledControlTextColor

        valueLabel.textColor = enabled
            ? .labelColor
            : .disabledControlTextColor

        minimumLabel.alphaValue =
            enabled ? 1.0 : 0.55
        maximumLabel.alphaValue =
            enabled ? 1.0 : 0.55
    }

    private func quantize(
        _ value: Int
    ) -> Int {
        let clamped = min(0, max(-60, value))
        let offset = clamped + 60

        return -60 + Int(
            (
                Double(offset) / 3.0
            ).rounded()
        ) * 3
    }

    @objc
    private func sliderChanged(
        _ sender: NSSlider
    ) {
        setValue(
            Int(sender.doubleValue.rounded()),
            notify: true
        )
    }
}
