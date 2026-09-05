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

    func transcribe(
        _ chunk: AudioChunk,
        language: String?,
        initialPrompt: String? = nil
    ) async throws -> String {
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
            initialPrompt: initialPrompt,
            maxInitialPromptTokens: 224,
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
        _ = try await transcribe(
            silence,
            language: language,
            initialPrompt: "Local Transcribe context warm-up."
        )
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

enum PromptContextBuilder {
    static let maximumRecentCharacters = 900
    static let maximumContextCharacters = 900

    static func build(sessionContext: String, transcript: String) -> String? {
        let context = compact(sessionContext, limit: maximumContextCharacters)
        let recent = compactTail(transcript, limit: maximumRecentCharacters)

        switch (recent.isEmpty, context.isEmpty) {
        case (true, true): return nil
        case (false, true): return recent
        case (true, false): return context
        case (false, false): return recent + "\n" + context
        }
    }

    private static func compact(_ text: String, limit: Int) -> String {
        let normalized = text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return String(normalized.prefix(limit))
    }

    private static func compactTail(_ text: String, limit: Int) -> String {
        let normalized = text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return String(normalized.suffix(limit))
    }
}

enum TranscriptionError: LocalizedError {
    case modelNotLoaded

    var errorDescription: String? { "The transcription model is not loaded." }
}
