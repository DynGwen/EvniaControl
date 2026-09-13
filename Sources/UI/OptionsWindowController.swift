import AppKit
import Combine

@MainActor
final class OptionsWindowController: NSWindowController {
    static let shared = OptionsWindowController()

    private let attenuationView = AttenuationControlView(
        frame: NSRect(
            x: 0,
            y: 0,
            width: 536,
            height: AttenuationControlView.preferredHeight
        )
    )

    private let launchCheckbox = NSButton(
        checkboxWithTitle: "Launch Evnia Control at login",
        target: nil,
        action: nil
    )

    private let statusLabel = NSTextField(labelWithString: "")
    private var cancellables = Set<AnyCancellable>()

    private init() {
        super.init(window: nil)
        configureWindow()
        bindModel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        refreshControls()

        guard let window else {
            return
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func configureWindow() {
        let width: CGFloat = 560
        let height: CGFloat = 230

        let content = NSView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: width,
                height: height
            )
        )

        // Full-size content view integrates the title bar into the Tahoe
        // surface. The controls are intentionally shifted slightly
        // downward so the visible content area remains vertically balanced.
        launchCheckbox.target = self
        launchCheckbox.action = #selector(toggleLaunchAtLogin(_:))
        launchCheckbox.frame = NSRect(
            x: 20,
            y: 168,
            width: width - 40,
            height: 22
        )

        attenuationView.frame = NSRect(
            x: 12,
            y: 61,
            width: width - 24,
            height: AttenuationControlView.preferredHeight
        )

        attenuationView.onChange = { value in
            AppModel.shared.setAttenuationDB(value)
            self.refreshStatus()
        }

        statusLabel.frame = NSRect(
            x: 20,
            y: 20,
            width: width - 40,
            height: 32
        )
        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.maximumNumberOfLines = 2

        content.addSubview(launchCheckbox)
        content.addSubview(attenuationView)
        content.addSubview(statusLabel)

        let window = NSWindow(
            contentRect: content.frame,
            styleMask: [
                .titled,
                .closable,
                .fullSizeContentView,
            ],
            backing: .buffered,
            defer: false
        )

        window.title = "Options Evnia Control"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .visible
        window.toolbarStyle = .unifiedCompact
        window.isMovableByWindowBackground = true
        window.contentView = TahoeWindowAppearance.appKitSurface(
            contentView: content,
            roundsOwnSurface: false
        )
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed

        TahoeWindowAppearance.apply(to: window)

        self.window = window
    }

    private func bindModel() {
        AppModel.shared.$attenuationDB
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.attenuationView.setValue(value, notify: false)
            }
            .store(in: &cancellables)

        AppModel.shared.$isConnected
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshControls()
            }
            .store(in: &cancellables)

        AppModel.shared.$attenuationStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshStatus()
            }
            .store(in: &cancellables)
    }

    private func refreshControls() {
        LoginItemManager.shared.refresh()

        launchCheckbox.state = LoginItemManager.shared.isEnabled
            ? .on
            : .off

        attenuationView.setValue(
            AppModel.shared.attenuationDB,
            notify: false
        )

        attenuationView.setEnabled(true)
        refreshStatus()
    }

    private func refreshStatus() {
        if let message = AppModel.shared.attenuationStatus {
            statusLabel.stringValue = "Audio: \(message)"
        } else if AppModel.shared.attenuationDB < 0 {
            statusLabel.stringValue = "Audio attenuation is active via Core Audio."
        } else {
            statusLabel.stringValue = "0 dB: no attenuation."
        }
    }

    @objc
    private func toggleLaunchAtLogin(_ sender: NSButton) {
        LoginItemManager.shared.setEnabled(sender.state == .on)
    }
}
