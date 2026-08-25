import AVFoundation
import Foundation

struct AudioChunk: Sendable {
    let samples: [Float]
    let sampleRate: Double
    let capturedSampleCount: Int

    var duration: TimeInterval { Double(samples.count) / sampleRate }
}

final class AudioSampleBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var samples: [Float] = []
    private var sampleRate: Double = 48_000

    func reset(sampleRate: Double) {
        lock.lock()
        samples.removeAll(keepingCapacity: true)
        self.sampleRate = sampleRate
        lock.unlock()
    }

    func append(_ newSamples: UnsafeBufferPointer<Float>) {
        lock.lock()
        samples.append(contentsOf: newSamples)
        lock.unlock()
    }

    func snapshot(minimumDuration: TimeInterval) -> AudioChunk? {
        lock.lock()
        defer { lock.unlock() }
        guard Double(samples.count) / sampleRate >= minimumDuration else { return nil }
        return AudioChunk(samples: samples, sampleRate: sampleRate, capturedSampleCount: samples.count)
    }

    func commit(_ chunk: AudioChunk, keepingOverlap overlap: TimeInterval) {
        lock.lock()
        let removable = max(0, chunk.capturedSampleCount - Int(overlap * sampleRate))
        if removable > 0, removable <= samples.count { samples.removeFirst(removable) }
        lock.unlock()
    }
}

@MainActor
final class AudioRecorder {
    private let engine = AVAudioEngine()
    private let sampleBuffer = AudioSampleBuffer()

    var buffer: AudioSampleBuffer { sampleBuffer }

    func start() async throws {
        let allowed = await AVCaptureDevice.requestAccess(for: .audio)
        guard allowed else { throw AudioRecorderError.permissionDenied }

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { throw AudioRecorderError.inputUnavailable }

        sampleBuffer.reset(sampleRate: format.sampleRate)
        input.removeTap(onBus: 0)
        let tap: AVAudioNodeTapBlock = { @Sendable [sampleBuffer] buffer, _ in
            guard let channel = buffer.floatChannelData?[0] else { return }
            sampleBuffer.append(UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength)))
        }
        input.installTap(onBus: 0, bufferSize: 4_096, format: format, block: tap)
        engine.prepare()
        try engine.start()
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }
}

enum AudioRecorderError: LocalizedError {
    case permissionDenied
    case inputUnavailable
    case noSamplesCaptured

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Microphone access was denied. Enable it in System Settings → Privacy & Security → Microphone."
        case .inputUnavailable:
            "No usable microphone input is available."
        case .noSamplesCaptured:
            "The microphone started but no audio samples were captured."
        }
    }
}
