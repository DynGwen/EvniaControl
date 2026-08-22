import Foundation

struct ProcessResult: Sendable {
    let status: Int32
    let stdout: String
    let stderr: String

    var succeeded: Bool {
        status == 0
    }
}

enum ProcessRunnerError: Error {
    case launchFailed(String)
    case timedOut
}

enum ProcessRunner {
    static func run(
        executable: URL,
        arguments: [String],
        timeout: TimeInterval = 2.0
    ) throws -> ProcessResult {
        let process = Process()
        let output = Pipe()
        let error = Pipe()
        let semaphore = DispatchSemaphore(value: 0)

        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = error
        process.terminationHandler = { _ in
            semaphore.signal()
        }

        do {
            try process.run()
        } catch {
            throw ProcessRunnerError.launchFailed(
                error.localizedDescription
            )
        }

        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            process.terminate()
            _ = semaphore.wait(timeout: .now() + 0.4)
            throw ProcessRunnerError.timedOut
        }

        let stdoutData = output.fileHandleForReading.readDataToEndOfFile()
        let stderrData = error.fileHandleForReading.readDataToEndOfFile()

        return ProcessResult(
            status: process.terminationStatus,
            stdout: String(
                data: stdoutData,
                encoding: .utf8
            ) ?? "",
            stderr: String(
                data: stderrData,
                encoding: .utf8
            ) ?? ""
        )
    }
}
