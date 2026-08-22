import AppKit
import Combine

@MainActor
final class OptionsWindowController:
    NSWindowController {
    static let shared = OptionsWindowController()

    private let attenuationView =
        AttenuationControlView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: 536,
                height:
                    AttenuationControlView.preferredHeight
            )
        )

    private let launchCheckbox =
        NSButton(
            checkboxWithTitle:
                "Launch Evnia Control at login",
            target: nil,
            action: nil
        )

    private let statusLabel =
        NSTextField(labelWithString: "")

    private var cancellables =
        Set<AnyCancellable>()

    private init() {
        super.init(window: nil)
        configureWindow()
        bindModel()
    }

    required init?(coder: NSCoder) {
        fatalError(
            "init(coder:) has not been implemented"
        )
    }

    func show() {
        refreshControls()

        guard let window else {
            return
        }

        NSApplication.shared.activate(
            ignoringOtherApps: true
        )
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

        launchCheckbox.target = self
        launchCheckbox.action =
            #selector(toggleLaunchAtLogin(_:))
        launchCheckbox.frame = NSRect(
            x: 20,
            y: 184,
            width: width - 40,
            height: 22
        )

        attenuationView.frame = NSRect(
            x: 12,
            y: 73,
            width: width - 24,
            height:
                AttenuationControlView.preferredHeight
        )

        attenuationView.onChange = {
            value in

            AppModel.shared
                .setAttenuationDB(value)

            self.refreshStatus()
        }

        statusLabel.frame = NSRect(
            x: 20,
            y: 24,
            width: width - 40,
            height: 36
        )
        statusLabel.font =
            .systemFont(ofSize: 11)
        statusLabel.textColor =
            .secondaryLabelColor
        statusLabel.lineBreakMode =
            .byWordWrapping
        statusLabel.maximumNumberOfLines = 2

        content.addSubview(launchCheckbox)
        content.addSubview(attenuationView)
        content.addSubview(statusLabel)

        let window = NSWindow(
            contentRect: content.frame,
            styleMask: [
                .titled,
                .closable,
            ],
            backing: .buffered,
            defer: false
        )

        window.title = "Evnia Control Options"
        window.contentView = content
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed

        self.window = window
    }

    private func bindModel() {
        AppModel.shared
            .$attenuationDB
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.attenuationView
                    .setValue(
                        value,
                        notify: false
                    )
            }
            .store(in: &cancellables)

        AppModel.shared
            .$isConnected
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshControls()
            }
            .store(in: &cancellables)

        AppModel.shared
            .$attenuationStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshStatus()
            }
            .store(in: &cancellables)
    }

    private func refreshControls() {
        LoginItemManager.shared.refresh()

        launchCheckbox.state =
            LoginItemManager.shared.isEnabled
                ? .on
                : .off

        attenuationView.setValue(
            AppModel.shared.attenuationDB,
            notify: false
        )

        // Audio attenuation is independent of DDC display
        // volume, so do not disable it when DDC is unavailable.
        attenuationView.setEnabled(true)

        refreshStatus()
    }

    private func refreshStatus() {
        if let message =
            AppModel.shared.attenuationStatus {
            statusLabel.stringValue =
                "Audio: \(message)"
        } else if AppModel.shared.attenuationDB < 0 {
            statusLabel.stringValue =
                "Audio attenuation active via Core Audio."
        } else {
            statusLabel.stringValue =
                "0 dB: no attenuation."
        }
    }

    @objc
    private func toggleLaunchAtLogin(
        _ sender: NSButton
    ) {
        LoginItemManager.shared.setEnabled(
            sender.state == .on
        )
    }
}
