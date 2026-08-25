import Foundation

struct TranscriptStore {
    enum StoreError: LocalizedError {
        case emptyTranscript

        var errorDescription: String? {
            "There is no transcript to save yet."
        }
    }

    private let fileManager: FileManager
    private let isoFormatter: ISO8601DateFormatter

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.isoFormatter = ISO8601DateFormatter()
    }

    func save(_ session: TranscriptSession, to folder: URL) throws -> URL {
        let cleanedText = session.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedText.isEmpty else { throw StoreError.emptyTranscript }

        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        let destination = uniqueDestination(for: session, in: folder)
        let markdown = render(session, text: cleanedText)
        try markdown.write(to: destination, atomically: true, encoding: .utf8)
        return destination
    }

    func render(_ session: TranscriptSession, text: String? = nil) -> String {
        let transcript = text ?? session.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let language = session.language?.isEmpty == false ? session.language! : "auto"
        let title = session.title.isEmpty ? "Untitled meeting" : session.title
        let safeTitle = yamlQuoted(title)

        return """
        ---
        title: \(safeTitle)
        created: "\(isoFormatter.string(from: session.startedAt))"
        duration_seconds: \(Int(session.duration.rounded()))
        model: \(yamlQuoted(session.model))
        language: \(yamlQuoted(language))
        ---

        # \(title)

        \(transcript)
        """ + "\n"
    }

    private func uniqueDestination(for session: TranscriptSession, in folder: URL) -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmm"
        let timestamp = dateFormatter.string(from: session.startedAt)
        let stem = "\(timestamp)-\(slug(session.title))"
        var candidate = folder.appendingPathComponent(stem).appendingPathExtension("md")
        var suffix = 2

        while fileManager.fileExists(atPath: candidate.path) {
            candidate = folder.appendingPathComponent("\(stem)-\(suffix)").appendingPathExtension("md")
            suffix += 1
        }
        return candidate
    }

    private func slug(_ value: String) -> String {
        let source = value.isEmpty ? "meeting" : value
        let allowed = CharacterSet.alphanumerics
        let pieces = source.lowercased().components(separatedBy: allowed.inverted).filter { !$0.isEmpty }
        return String(pieces.joined(separator: "-").prefix(64)).isEmpty ? "meeting" : String(pieces.joined(separator: "-").prefix(64))
    }

    private func yamlQuoted(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}
