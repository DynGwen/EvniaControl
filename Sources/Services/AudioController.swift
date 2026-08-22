import CoreAudioTapKit
import Foundation
import os.lock

final class GainProcessor: AudioProcessor {
    private var gain: Float = 1.0
    private var lock = os_unfair_lock_s()

    func prepare(sampleRate: Double) {
        _ = sampleRate
    }

    func setDecibels(_ decibels: Int) {
        let clamped = min(0, max(-60, decibels))
        let newGain = Float(
            pow(
                10.0,
                Double(clamped) / 20.0
            )
        )

        os_unfair_lock_lock(&lock)
        gain = newGain
        os_unfair_lock_unlock(&lock)
    }

    func process(
        _ samples: UnsafeMutablePointer<Float>,
        frameCount: Int,
        channelCount: Int
    ) {
        os_unfair_lock_lock(&lock)
        let currentGain = gain
        os_unfair_lock_unlock(&lock)

        let sampleCount = frameCount * channelCount

        guard currentGain != 1 else {
            return
        }

        for index in 0..<sampleCount {
            samples[index] *= currentGain
        }
    }
}

@MainActor
final class AudioController {
    enum State: Equatable {
        case stopped
        case running
        case failed(String)
    }

    private let processor = GainProcessor()
    private lazy var engine =
        SystemAudioTapEngine(processor: processor)

    private(set) var state: State = .stopped

    // The output used when attenuation was successfully started.
    // It is deliberately preserved while the screen is asleep.
    private var preferredOutputUID: String?

    func setAttenuation(decibels: Int) {
        processor.setDecibels(decibels)
    }

    func start(decibels: Int) throws {
        guard decibels < 0 else {
            stop()
            return
        }

        if state == .running {
            setAttenuation(decibels: decibels)
            return
        }

        guard #available(macOS 14.2, *) else {
            throw audioError(
                code: 1,
                message:
                    "macOS 14.2 or later is required for audio attenuation."
            )
        }

        guard let output =
            try AudioDevices.defaultOutput()
        else {
            throw audioError(
                code: 2,
                message:
                    "No default audio output is available."
            )
        }

        try startEngine(
            decibels: decibels,
            outputUID: output.uid,
            rememberAsPreferred: true
        )
    }

    func prepareForWakeRestart() {
        // Important: do this AFTER wake, never while the display audio
        // device is disappearing. This follows the lifecycle used by
        // the working 0.2.7 implementation: full stop, then rebuild.
        stopEngine(
            resetPreferredOutput: false,
            resetProcessorGain: false
        )
    }

    func resumePreferredOutput(
        decibels: Int
    ) throws -> Bool {
        guard decibels < 0 else {
            stop()
            return true
        }

        guard #available(macOS 14.2, *) else {
            throw audioError(
                code: 1,
                message:
                    "macOS 14.2 or later is required for audio attenuation."
            )
        }

        guard let preferredOutputUID else {
            try start(decibels: decibels)
            return true
        }

        let outputs = try AudioDevices.outputs()

        guard outputs.contains(
            where: { $0.uid == preferredOutputUID }
        ) else {
            return false
        }

        try startEngine(
            decibels: decibels,
            outputUID: preferredOutputUID,
            rememberAsPreferred: false
        )

        return true
    }

    func resumeDefaultOutput(
        decibels: Int
    ) throws {
        guard decibels < 0 else {
            stop()
            return
        }

        guard let output =
            try AudioDevices.defaultOutput()
        else {
            throw audioError(
                code: 2,
                message:
                    "No default audio output is available."
            )
        }

        // Do not overwrite preferredOutputUID here. If macOS has
        // temporarily fallen back to the Mac's speakers, keep the
        // previous Evnia UID so a later wake can still recover it.
        try startEngine(
            decibels: decibels,
            outputUID: output.uid,
            rememberAsPreferred: false
        )
    }

    func stop() {
        stopEngine(
            resetPreferredOutput: true,
            resetProcessorGain: true
        )
    }

    private func startEngine(
        decibels: Int,
        outputUID: String,
        rememberAsPreferred: Bool
    ) throws {
        engine.stop()
        state = .stopped

        processor.setDecibels(decibels)

        do {
            try engine.start(
                outputUID: outputUID
            )

            if rememberAsPreferred
                || preferredOutputUID == nil {
                preferredOutputUID = outputUID
            }

            state = .running
        } catch {
            engine.stop()
            state = .failed(
                error.localizedDescription
            )
            throw error
        }
    }

    private func stopEngine(
        resetPreferredOutput: Bool,
        resetProcessorGain: Bool
    ) {
        engine.stop()
        state = .stopped

        if resetPreferredOutput {
            preferredOutputUID = nil
        }

        if resetProcessorGain {
            processor.setDecibels(0)
        }
    }

    private func audioError(
        code: Int,
        message: String
    ) -> NSError {
        state = .failed(message)

        return NSError(
            domain: "EvniaControl.Audio",
            code: code,
            userInfo: [
                NSLocalizedDescriptionKey: message
            ]
        )
    }
}
