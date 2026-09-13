import AppKit
import SwiftUI

@MainActor
enum TahoeWindowAppearance {
    static let cornerRadius: CGFloat = 16

    static func apply(to window: NSWindow) {
        window.isOpaque = false
        window.backgroundColor = .clear

        guard let frameView = window.contentView?.superview else {
            applyCorners(to: window.contentView)
            return
        }

        applyCorners(to: frameView)
    }

    static func appKitSurface(
        contentView: NSView,
        roundsOwnSurface: Bool = true
    ) -> NSView {
        if #available(macOS 26.0, *) {
            let glassView = NSGlassEffectView()
            glassView.style = .regular

            if roundsOwnSurface {
                glassView.cornerRadius = cornerRadius
            }

            glassView.contentView = contentView
            return glassView
        }

        let effectView = NSVisualEffectView()
        effectView.material = .windowBackground
        effectView.blendingMode = .behindWindow
        effectView.state = .followsWindowActiveState

        contentView.translatesAutoresizingMaskIntoConstraints = false
        effectView.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: effectView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: effectView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: effectView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: effectView.bottomAnchor),
        ])

        if roundsOwnSurface {
            applyCorners(to: effectView)
        }

        return effectView
    }

    private static func applyCorners(to view: NSView?) {
        guard let view else {
            return
        }

        view.wantsLayer = true
        view.layer?.cornerRadius = cornerRadius
        view.layer?.cornerCurve = .continuous
        view.layer?.masksToBounds = true
    }
}

@MainActor
private final class TahoeWindowProbe: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        guard let window else {
            return
        }

        TahoeWindowAppearance.apply(to: window)
    }
}

struct TahoeWindowBridge: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        TahoeWindowProbe(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let window = nsView.window else {
            return
        }

        TahoeWindowAppearance.apply(to: window)
    }
}

private struct TahoeWindowSurfaceModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            let shape = RoundedRectangle(
                cornerRadius: TahoeWindowAppearance.cornerRadius,
                style: .continuous
            )

            content
                .glassEffect(
                    .regular,
                    in: shape
                )
                .clipShape(shape)
                .compositingGroup()
                .background(
                    TahoeWindowBridge()
                        .frame(width: 0, height: 0)
                )
        } else {
            content
                .background(
                    .regularMaterial,
                    in: RoundedRectangle(
                        cornerRadius: TahoeWindowAppearance.cornerRadius,
                        style: .continuous
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: TahoeWindowAppearance.cornerRadius,
                        style: .continuous
                    )
                )
                .background(
                    TahoeWindowBridge()
                        .frame(width: 0, height: 0)
                )
        }
    }
}

extension View {
    func tahoeWindowSurface() -> some View {
        modifier(TahoeWindowSurfaceModifier())
    }
}
