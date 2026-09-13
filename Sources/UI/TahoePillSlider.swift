import SwiftUI

struct TahoePillSlider: View {
    @Binding var value: Double

    let range: ClosedRange<Double>
    let step: Double
    var isEnabled = true
    var showsGraduations = false
    var graduationCount = 0

    private let trackHeight: CGFloat = 6
    private let thumbWidth: CGFloat = 20
    private let thumbHeight: CGFloat = 16

    var body: some View {
        VStack(spacing: showsGraduations ? 4 : 0) {
            GeometryReader { geometry in
                let usableWidth = max(1, geometry.size.width - thumbWidth)
                let progress = normalized(value)
                let thumbX = (thumbWidth / 2) + (usableWidth * progress)
                let activeWidth = max(0, thumbX - (thumbWidth / 2))

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(
                            Color.secondary.opacity(
                                isEnabled ? 0.18 : 0.10
                            )
                        )
                        .frame(height: trackHeight)
                        .padding(.horizontal, thumbWidth / 2)

                    Capsule()
                        .fill(
                            Color.accentColor.opacity(
                                isEnabled ? 1.0 : 0.45
                            )
                        )
                        .frame(
                            width: activeWidth,
                            height: trackHeight
                        )
                        .padding(.leading, thumbWidth / 2)

                    RoundedRectangle(
                        cornerRadius: 8,
                        style: .continuous
                    )
                    .fill(
                        Color(
                            nsColor: .controlBackgroundColor
                        )
                    )
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: 8,
                            style: .continuous
                        )
                        .stroke(
                            Color.secondary.opacity(0.22),
                            lineWidth: 1
                        )
                    )
                    .shadow(
                        color: Color.black.opacity(0.12),
                        radius: 2,
                        y: 1
                    )
                    .frame(
                        width: thumbWidth,
                        height: thumbHeight
                    )
                    .position(
                        x: thumbX,
                        y: thumbHeight / 2
                    )
                }
                .frame(height: thumbHeight)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            guard isEnabled else {
                                return
                            }

                            let x = min(
                                usableWidth,
                                max(
                                    0,
                                    gesture.location.x
                                        - (thumbWidth / 2)
                                )
                            )

                            let progress = x / usableWidth
                            let rawValue =
                                range.lowerBound
                                + progress
                                    * (
                                        range.upperBound
                                        - range.lowerBound
                                    )

                            value = quantize(rawValue)
                        }
                )
                .opacity(isEnabled ? 1 : 0.55)
            }
            .frame(height: thumbHeight)

            if showsGraduations && graduationCount > 1 {
                HStack(spacing: 0) {
                    ForEach(
                        0..<graduationCount,
                        id: \.self
                    ) { index in
                        Rectangle()
                            .fill(
                                Color.secondary.opacity(
                                    index % 5 == 0
                                        ? 0.48
                                        : 0.26
                                )
                            )
                            .frame(
                                width: 1,
                                height: index % 5 == 0
                                    ? 5
                                    : 3
                            )

                        if index < graduationCount - 1 {
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.horizontal, thumbWidth / 2)
                .opacity(isEnabled ? 1 : 0.55)
            }
        }
        .accessibilityAdjustableAction { direction in
            guard isEnabled else {
                return
            }

            switch direction {
            case .increment:
                value = quantize(value + step)

            case .decrement:
                value = quantize(value - step)

            @unknown default:
                break
            }
        }
    }

    private func normalized(
        _ currentValue: Double
    ) -> CGFloat {
        let clamped = min(
            range.upperBound,
            max(
                range.lowerBound,
                currentValue
            )
        )

        let span =
            range.upperBound
            - range.lowerBound

        guard span > 0 else {
            return 0
        }

        return CGFloat(
            (
                clamped
                - range.lowerBound
            ) / span
        )
    }

    private func quantize(
        _ rawValue: Double
    ) -> Double {
        let clamped = min(
            range.upperBound,
            max(
                range.lowerBound,
                rawValue
            )
        )

        guard step > 0 else {
            return clamped
        }

        let offset =
            (
                clamped
                - range.lowerBound
            ) / step

        let stepped =
            range.lowerBound
            + offset.rounded()
                * step

        return min(
            range.upperBound,
            max(
                range.lowerBound,
                stepped
            )
        )
    }
}
