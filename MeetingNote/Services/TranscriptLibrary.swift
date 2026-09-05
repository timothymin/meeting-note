import Foundation

struct TranscriptLibrary {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) { self.fileManager = fileManager }

    func load(from folder: URL) throws -> [TranscriptFile] {
        guard fileManager.fileExists(atPath: folder.path) else { return [] }
        let urls = try fileManager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.contentModificationDateKey, .creationDateKey],
            options: [.skipsHiddenFiles]
        )
        return urls
            .filter { $0.pathExtension.lowercased() == "md" }
            .compactMap(parse)
            .sorted { $0.createdAt > $1.createdAt }
    }

    func moveToTrash(_ file: TranscriptFile) throws {
        var result: NSURL?
        try fileManager.trashItem(at: file.url, resultingItemURL: &result)
    }

    private func parse(_ url: URL) -> TranscriptFile? {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let values = frontMatter(in: content)
        let resources = try? url.resourceValues(forKeys: [.contentModificationDateKey, .creationDateKey])
        let created = values["created"].flatMap(ISO8601DateFormatter().date)
            ?? resources?.creationDate ?? resources?.contentModificationDate ?? .distantPast
        let title = values["title"]?.unquoted
            ?? content.split(separator: "\n").first(where: { $0.hasPrefix("# ") }).map { String($0.dropFirst(2)) }
            ?? url.deletingPathExtension().lastPathComponent
        let body = bodyText(in: content)
        let preview = body.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)

        return TranscriptFile(
            url: url,
            title: title,
            createdAt: created,
            duration: values["duration_seconds"].flatMap { TimeInterval($0.unquoted) },
            preview: String(preview.prefix(140)),
            content: body,
            contextPrompt: values["context"]?.unquoted ?? ""
        )
    }

    private func frontMatter(in content: String) -> [String: String] {
        let lines = content.components(separatedBy: .newlines)
        guard lines.first == "---", let closing = lines.dropFirst().firstIndex(of: "---") else { return [:] }
        return lines[1..<closing].reduce(into: [:]) { values, line in
            guard let separator = line.firstIndex(of: ":") else { return }
            values[String(line[..<separator])] = String(line[line.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
        }
    }

    private func bodyText(in content: String) -> String {
        var lines = content.components(separatedBy: .newlines)
        if lines.first == "---", let closing = lines.dropFirst().firstIndex(of: "---") {
            lines.removeSubrange(0...closing)
        }
        while lines.first?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true { lines.removeFirst() }
        if lines.first?.hasPrefix("# ") == true { lines.removeFirst() }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension String {
    var unquoted: String {
        guard count >= 2, first == "\"", last == "\"" else { return self }
        return String(dropFirst().dropLast())
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\r", with: "\r")
            .replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
}
