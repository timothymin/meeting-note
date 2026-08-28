import AppKit
import Foundation

enum ModelPreparationState: Equatable {
    case preparing
    case ready
    case failed
}

@MainActor
final class AppModel: ObservableObject {
    static let defaultModelID = "mlx-community/whisper-large-v3-turbo"

    @Published var title = ""
    @Published var confirmedText = ""
    @Published var isRecording = false
    @Published var isBusy = false
    @Published var status = "Ready"
    @Published var errorMessage: String?
    @Published var lastSavedURL: URL?
    @Published var recentFiles: [TranscriptFile] = []
    @Published var selectedTranscript: TranscriptFile?
    @Published private(set) var modelPreparationState: ModelPreparationState = .preparing

    @Published var selectedModel: String {
        didSet {
            defaults.set(selectedModel, forKey: Keys.model)
            guard selectedModel != oldValue else { return }
            modelSelectionDidChange()
        }
    }
    @Published var language: String {
        didSet { defaults.set(language, forKey: Keys.language) }
    }
    @Published var outputFolder: URL {
        didSet {
            defaults.set(outputFolder.path, forKey: Keys.outputFolder)
            refreshLibrary()
        }
    }
    let availableModels = [
        "mlx-community/whisper-large-v3-turbo",
        "mlx-community/whisper-large-v3-mlx",
        "openai/whisper-small",
        "openai/whisper-base"
    ]

    private enum Keys {
        static let model = "selectedModel"
        static let language = "language"
        static let outputFolder = "outputFolder"
    }

    private let defaults: UserDefaults
    private let store = TranscriptStore()
    private let library = TranscriptLibrary()
    private let recorder = AudioRecorder()
    private let engine = WhisperTranscriptionEngine()
    private var startedAt: Date?
    private var transcriptionLoop: Task<Void, Never>?
    private var modelPreparationTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.selectedModel = defaults.string(forKey: Keys.model) ?? Self.defaultModelID
        self.language = defaults.string(forKey: Keys.language) ?? "auto"
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let newDefaultFolder = documents.appendingPathComponent("Local Transcribe", isDirectory: true)
        let legacyDefaultFolder = documents.appendingPathComponent("Meeting Notes", isDirectory: true)

        if let savedPath = defaults.string(forKey: Keys.outputFolder) {
            let savedFolder = URL(fileURLWithPath: savedPath, isDirectory: true)
            if savedFolder.standardizedFileURL == legacyDefaultFolder.standardizedFileURL {
                if !fileManager.fileExists(atPath: newDefaultFolder.path),
                   fileManager.fileExists(atPath: legacyDefaultFolder.path) {
                    try? fileManager.moveItem(at: legacyDefaultFolder, to: newDefaultFolder)
                }
                if fileManager.fileExists(atPath: newDefaultFolder.path) {
                    self.outputFolder = newDefaultFolder
                    defaults.set(newDefaultFolder.path, forKey: Keys.outputFolder)
                } else {
                    self.outputFolder = savedFolder
                }
            } else {
                self.outputFolder = savedFolder
            }
        } else {
            self.outputFolder = newDefaultFolder
        }
        refreshLibrary()
        scheduleModelPreparation()
    }

    var displayText: String { confirmedText }
    var isModelReady: Bool { modelPreparationState == .ready }
    var isPreparingModel: Bool { modelPreparationState == .preparing }

    func toggleRecording() {
        Task { isRecording ? await stopRecording() : await startRecording() }
    }

    func startRecording() async {
        guard !isRecording, !isBusy else { return }
        guard isModelReady else {
            errorMessage = "Wait for the Whisper model to finish loading before starting transcription."
            return
        }
        isBusy = true
        errorMessage = nil
        lastSavedURL = nil
        confirmedText = ""
        startedAt = Date()

        do {
            status = "Starting microphone…"
            try await recorder.start()
            isRecording = true
            isBusy = false
            status = "Listening"
            startTranscriptionLoop()
        } catch {
            recorder.stop()
            startedAt = nil
            isRecording = false
            isBusy = false
            status = "Could not start"
            errorMessage = error.localizedDescription
        }
    }

    func stopRecording() async {
        guard isRecording || isBusy else { return }
        isBusy = true
        isRecording = false
        transcriptionLoop?.cancel()
        transcriptionLoop = nil
        recorder.stop()
        status = "Finishing transcript…"

        do {
            try await transcribeAvailableAudio(minimumDuration: 0.35)
        } catch {
            errorMessage = "Final audio could not be transcribed: \(error.localizedDescription)"
        }

        let finalText = confirmedText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let startedAt, !finalText.isEmpty {
            let session = TranscriptSession(
                id: UUID(),
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                startedAt: startedAt,
                endedAt: Date(),
                text: finalText,
                model: selectedModel,
                language: language
            )
            do {
                lastSavedURL = try store.save(session, to: outputFolder)
                status = "Saved"
                refreshLibrary()
            } catch {
                errorMessage = error.localizedDescription
                status = "Save failed"
            }
        } else {
            status = "Stopped — no speech captured"
        }

        self.startedAt = nil
        isBusy = false
    }

    func prepareModel() async {
        guard !isRecording else { return }
        let targetModel = selectedModel
        modelPreparationState = .preparing
        errorMessage = nil
        status = "Preparing Whisper…"

        do {
            try await engine.load(modelID: targetModel)
            guard selectedModel == targetModel else {
                scheduleModelPreparation()
                return
            }
            status = "Warming up Whisper…"
            try await engine.warmUp(language: language)
            guard selectedModel == targetModel else {
                scheduleModelPreparation()
                return
            }
            modelPreparationState = .ready
            status = "Model ready"
        } catch is CancellationError {
            return
        } catch {
            guard selectedModel == targetModel else { return }
            modelPreparationState = .failed
            status = "Model unavailable"
            errorMessage = "Could not prepare (targetModel): (error.localizedDescription)"
        }
    }

    func runMLXSmokeTest() async throws {
        try await engine.load(modelID: selectedModel)
        try await engine.warmUp(language: "en")
    }

    func runAudioCaptureSmokeTest() async throws {
        try await recorder.start()
        defer { recorder.stop() }
        try await Task.sleep(for: .seconds(1))
        guard recorder.buffer.snapshot(minimumDuration: 0.1) != nil else {
            throw AudioRecorderError.noSamplesCaptured
        }
    }

    func refreshLibrary() {
        do {
            recentFiles = try library.load(from: outputFolder)
            if let selectedTranscript,
               let refreshed = recentFiles.first(where: { $0.url == selectedTranscript.url }) {
                self.selectedTranscript = refreshed
            }
        } catch {
            errorMessage = "Could not read transcript folder: \(error.localizedDescription)"
        }
    }

    func selectTranscript(_ file: TranscriptFile) { selectedTranscript = file }

    func deleteTranscript(_ file: TranscriptFile) {
        do {
            try library.moveToTrash(file)
            if selectedTranscript == file { selectedTranscript = nil }
            refreshLibrary()
        } catch {
            errorMessage = "Could not move the transcript to Trash: \(error.localizedDescription)"
        }
    }

    func chooseOutputFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose transcript folder"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = outputFolder
        if panel.runModal() == .OK, let url = panel.url { outputFolder = url }
    }

    func revealOutputFolder() {
        try? FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
        NSWorkspace.shared.activateFileViewerSelecting(lastSavedURL.map { [$0] } ?? [outputFolder])
    }

    func reveal(_ file: TranscriptFile) {
        NSWorkspace.shared.activateFileViewerSelecting([file.url])
    }

    func copyTranscript() {
        let text = selectedTranscript?.content ?? displayText
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func modelSelectionDidChange() {
        modelPreparationState = .preparing
        status = "Preparing Whisper…"
        scheduleModelPreparation()
    }

    private func scheduleModelPreparation() {
        modelPreparationTask?.cancel()
        modelPreparationTask = Task { [weak self] in
            await self?.prepareModel()
        }
    }

    private func startTranscriptionLoop() {
        transcriptionLoop?.cancel()
        transcriptionLoop = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard let self, !Task.isCancelled, self.isRecording else { break }
                do {
                    try await self.transcribeAvailableAudio(minimumDuration: 2)
                } catch {
                    self.errorMessage = error.localizedDescription
                    self.status = "Listening — transcription retrying"
                }
            }
        }
    }

    private func transcribeAvailableAudio(minimumDuration: TimeInterval) async throws {
        guard let chunk = recorder.buffer.snapshot(minimumDuration: minimumDuration) else { return }
        status = isRecording ? "Transcribing…" : status
        let newText = try await engine.transcribe(chunk, language: language)
        if !newText.isEmpty { confirmedText = TranscriptMerger.merge(confirmedText, with: newText) }
        recorder.buffer.commit(chunk, keepingOverlap: 1.25)
        if isRecording { status = "Listening" }
    }
}
