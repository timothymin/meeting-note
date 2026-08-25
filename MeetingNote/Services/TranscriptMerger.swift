import Foundation

enum TranscriptMerger {
    static func merge(_ existing: String, with incoming: String) -> String {
        let left = words(existing)
        let right = words(incoming)
        guard !left.isEmpty else { return incoming.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard !right.isEmpty else { return existing.trimmingCharacters(in: .whitespacesAndNewlines) }

        let maximum = min(left.count, right.count, 30)
        var overlap = 0
        if maximum > 0 {
            for size in stride(from: maximum, through: 1, by: -1) {
                if left.suffix(size).map(normalize).elementsEqual(right.prefix(size).map(normalize)) {
                    overlap = size
                    break
                }
            }
        }
        return (left + right.dropFirst(overlap)).joined(separator: " ")
    }

    private static func words(_ value: String) -> [String] {
        value.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    }

    private static func normalize(_ value: String) -> String {
        value.lowercased().trimmingCharacters(in: .punctuationCharacters)
    }
}
