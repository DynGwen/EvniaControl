import Foundation

actor M1DDCDriver {
    static let shared = M1DDCDriver()

    enum DriverError: LocalizedError {
        case helperMissing
        case displayNotFound
        case commandFailed(String)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .helperMissing:
                return "The built-in DDC engine could not be found."
            case .displayNotFound:
                return "No compatible Evnia display was detected."
            case let .commandFailed(message):
                return message
            case .invalidResponse:
                return "Invalid DDC response."
            }
        }
    }

    private var selectedDisplay: DisplayDescriptor?

    private var helperURL: URL? {
        Bundle.main.resourceURL?
            .appendingPathComponent("m1ddc", isDirectory: false)
    }

    func refresh() throws -> MonitorSnapshot {
        let displays = try listDisplays()
        guard let display = selectDisplay(from: displays) else {
            selectedDisplay = nil
            throw DriverError.displayNotFound
        }

        selectedDisplay = display

        let brightness = try? read(
            "luminance",
            display: display
        )
        let volume = try? read(
            "volume",
            display: display
        )

        guard brightness != nil || volume != nil else {
            throw DriverError.commandFailed(
                "The display was detected, but DDC/CI is not responding."
            )
        }

        return MonitorSnapshot(
            display: display,
            brightness: brightness,
            volume: volume
        )
    }

    func setBrightness(_ value: Int) throws {
        try write(
            "luminance",
            value: clamped(value),
            display: try activeDisplay()
        )
    }

    func setVolume(_ value: Int) throws {
        try write(
            "volume",
            value: clamped(value),
            display: try activeDisplay()
        )
    }

    func setMute(_ muted: Bool) throws {
        let display = try activeDisplay()
        let result = try execute([
            "display",
            String(display.index),
            "set",
            "mute",
            muted ? "on" : "off",
        ])

        guard result.succeeded else {
            throw DriverError.commandFailed(
                usefulMessage(from: result)
            )
        }
    }

    func listDisplays() throws -> [DisplayDescriptor] {
        let result = try execute([
            "display",
            "list",
            "detailed",
        ])

        guard result.succeeded else {
            throw DriverError.commandFailed(
                usefulMessage(from: result)
            )
        }

        return Self.parseDisplayList(result.stdout)
    }

    static func parseDisplayList(
        _ output: String
    ) -> [DisplayDescriptor] {
        var displays: [DisplayDescriptor] = []

        for rawLine in output.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard line.hasPrefix("["),
                  let closeBracket = line.firstIndex(of: "]"),
                  let openParen = line.lastIndex(of: "("),
                  let closeParen = line.lastIndex(of: ")"),
                  openParen < closeParen
            else {
                continue
            }

            let indexStart = line.index(after: line.startIndex)
            let indexText = String(
                line[indexStart..<closeBracket]
            )
            guard let index = Int(indexText) else {
                continue
            }

            let nameStart = line.index(after: closeBracket)
            let rawName = line[nameStart..<openParen]
            let name = rawName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            let uuidStart = line.index(after: openParen)
            let uuid = String(line[uuidStart..<closeParen])

            displays.append(
                DisplayDescriptor(
                    index: index,
                    name: name,
                    uuid: uuid
                )
            )
        }

        return displays
    }

    private func activeDisplay() throws -> DisplayDescriptor {
        if let selectedDisplay {
            return selectedDisplay
        }

        let displays = try listDisplays()
        guard let display = selectDisplay(from: displays) else {
            throw DriverError.displayNotFound
        }

        selectedDisplay = display
        return display
    }

    private func selectDisplay(
        from displays: [DisplayDescriptor]
    ) -> DisplayDescriptor? {
        if let preferred = displays.first(
            where: \.isPreferredEvnia
        ) {
            return preferred
        }

        // Safe fallback for the common one-external-monitor setup.
        if displays.count == 1 {
            return displays[0]
        }

        return nil
    }

    private func read(
        _ attribute: String,
        display: DisplayDescriptor
    ) throws -> Int {
        let result = try execute([
            "display",
            String(display.index),
            "get",
            attribute,
        ])

        guard result.succeeded else {
            throw DriverError.commandFailed(
                usefulMessage(from: result)
            )
        }

        let line = result.stdout
            .split(separator: "\n")
            .last?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let line,
              let value = Int(line)
        else {
            throw DriverError.invalidResponse
        }

        return clamped(value)
    }

    private func write(
        _ attribute: String,
        value: Int,
        display: DisplayDescriptor
    ) throws {
        let result = try execute([
            "display",
            String(display.index),
            "set",
            attribute,
            String(value),
        ])

        guard result.succeeded else {
            throw DriverError.commandFailed(
                usefulMessage(from: result)
            )
        }
    }

    private func execute(
        _ arguments: [String]
    ) throws -> ProcessResult {
        guard let helperURL,
              FileManager.default.isExecutableFile(
                atPath: helperURL.path
              )
        else {
            throw DriverError.helperMissing
        }

        do {
            return try ProcessRunner.run(
                executable: helperURL,
                arguments: arguments
            )
        } catch ProcessRunnerError.timedOut {
            throw DriverError.commandFailed(
                "DDC control timed out. " +
                "Disconnect and reconnect the display, then try again."
            )
        } catch {
            throw DriverError.commandFailed(
                error.localizedDescription
            )
        }
    }

    private func usefulMessage(
        from result: ProcessResult
    ) -> String {
        let stdout = result.stdout.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let stderr = result.stderr.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if !stdout.isEmpty {
            return stdout
        }
        if !stderr.isEmpty {
            return stderr
        }
        return "DDC command failed."
    }

    private func clamped(_ value: Int) -> Int {
        min(100, max(0, value))
    }
}
