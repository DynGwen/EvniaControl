import AppKit
import SwiftUI

@MainActor
enum TahoeWindowCorners {
    static let radius: CGFloat = 16

    static func apply(to window: NSWindow) {
        guard let frameView = window.contentView?.superview else {
            apply(to: window.contentView)
            return
        }

        apply(to: frameView)
    }

    private static func apply(to view: NSView?) {
        guard let view else {
            return
        }

        view.wantsLayer = true
        view.layer?.cornerRadius = radius
        view.layer?.cornerCurve = .continuous
        view.layer?.masksToBounds = true
    }
}

@MainActor
private final class TahoeWindowCornerProbe: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        guard let window else {
            return
        }

        DispatchQueue.main.async {
            TahoeWindowCorners.apply(to: window)
        }
    }
}

struct TahoeWindowCornerBridge: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        TahoeWindowCornerProbe(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let window = nsView.window else {
            return
        }

        TahoeWindowCorners.apply(to: window)
    }
}
