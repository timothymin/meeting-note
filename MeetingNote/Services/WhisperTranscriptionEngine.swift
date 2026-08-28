import Foundation
import MLXAudioCore
import MLXAudioSTT

actor WhisperTranscriptionEngine {
    private var model: (any STTGenerationModel)?
    private var loadedModelID: String?

    func load(modelID: String) async throws {
        guard loadedModelID != modelID || model == nil else { return }
        model = nil
        loadedModelID = nil
        model = try await WhisperModel.fromPretrained(modelID)
        loadedModelID = modelID
    }

    func transcribe(_ chunk: AudioChunk, language: String?) async throws -> String {
        guard let model else { throw TranscriptionError.modelNotLoaded }

        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("local-transcribe-\(UUID().uuidString)")
            .appendingPathExtension("wav")
        defer { try? FileManager.default.removeItem(at: temporaryURL) }

        try AudioUtils.writeWavFile(samples: chunk.samples, sampleRate: chunk.sampleRate, fileURL: temporaryURL)
        let (_, audio) = try loadAudioArray(from: temporaryURL, sampleRate: 16_000)
        let parameters = STTGenerateParameters(
            maxTokens: 448,
            temperature: 0,
            topP: 1,
            language: Self.normalizedLanguage(language),
            chunkDuration: 30,
            minChunkDuration: 0.5
        )
        return model.generate(audio: audio, generationParameters: parameters).text
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func warmUp(language: String?) async throws {
        let silence = AudioChunk(
            samples: [Float](repeating: 0, count: 8_000),
            sampleRate: 16_000,
            capturedSampleCount: 8_000
        )
        _ = try await transcribe(silence, language: language)
    }

    func unload() {
        model = nil
        loadedModelID = nil
    }

    private static func normalizedLanguage(_ language: String?) -> String? {
        guard let language else { return nil }
        let trimmed = language.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed.lowercased() == "auto" ? nil : trimmed.lowercased()
    }
}

enum TranscriptionError: LocalizedError {
    case modelNotLoaded

    var errorDescription: String? { "The transcription model is not loaded." }
}
