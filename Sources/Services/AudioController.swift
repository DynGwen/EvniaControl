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
            let message =
                "macOS 14.2 or later is required for audio attenuation."

            state = .failed(message)

            throw NSError(
                domain: "EvniaControl.Audio",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: message
                ]
            )
        }

        guard let output =
            try AudioDevices.defaultOutput()
        else {
            let message =
                "No default audio output is available."

            state = .failed(message)

            throw NSError(
                domain: "EvniaControl.Audio",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: message
                ]
            )
        }

        processor.setDecibels(decibels)

        do {
            try engine.start(outputUID: output.uid)
            state = .running
        } catch {
            engine.stop()
            state = .failed(
                error.localizedDescription
            )
            throw error
        }
    }

    func stop() {
        engine.stop()
        state = .stopped
        processor.setDecibels(0)
    }
}
