import Foundation

enum TranscriptMerger {
    static func merge(_ existing: String, with incoming: String) -> String {
        let left = words(existing)
        let right = words(incoming)
        guard !left.isEmpty else { return incoming.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard !right.isEmpty else { return existing.trimmingCharacters(in: .whitespacesAndNewlines) }

        let leftTail = Array(left.suffix(160))
        let matches = alignedMatches(leftTail.map(normalize), right.map(normalize))

        if let first = matches.first, let last = matches.last {
            let allowedEdgeDrift = max(8, right.count / 4)
            let startsNearIncomingBeginning = first.right <= allowedEdgeDrift
            let endsNearExistingEnd = last.left >= leftTail.count - allowedEdgeDrift - 1
            let minimumMatches = min(3, min(leftTail.count, right.count))

            if matches.count >= minimumMatches,
               startsNearIncomingBeginning,
               endsNearExistingEnd {
                let unseen = right.dropFirst(last.right + 1)
                return (left + unseen).joined(separator: " ")
            }
        }

        return (left + right).joined(separator: " ")
    }

    private struct Match {
        let left: Int
        let right: Int
    }

    /// Aligns two re-decoded rolling windows. Whisper may revise a few words
    /// between passes, so exact suffix/prefix matching is too brittle.
    private static func alignedMatches(_ left: [String], _ right: [String]) -> [Match] {
        guard !left.isEmpty, !right.isEmpty else { return [] }
        var lengths = Array(
            repeating: Array(repeating: 0, count: right.count + 1),
            count: left.count + 1
        )

        for leftIndex in 1...left.count {
            for rightIndex in 1...right.count {
                if left[leftIndex - 1] == right[rightIndex - 1] {
                    lengths[leftIndex][rightIndex] = lengths[leftIndex - 1][rightIndex - 1] + 1
                } else {
                    lengths[leftIndex][rightIndex] = max(
                        lengths[leftIndex - 1][rightIndex],
                        lengths[leftIndex][rightIndex - 1]
                    )
                }
            }
        }

        var matches: [Match] = []
        var leftIndex = left.count
        var rightIndex = right.count
        while leftIndex > 0, rightIndex > 0 {
            if left[leftIndex - 1] == right[rightIndex - 1] {
                matches.append(Match(left: leftIndex - 1, right: rightIndex - 1))
                leftIndex -= 1
                rightIndex -= 1
            } else if lengths[leftIndex - 1][rightIndex] >= lengths[leftIndex][rightIndex - 1] {
                leftIndex -= 1
            } else {
                rightIndex -= 1
            }
        }
        return matches.reversed()
    }

    private static func words(_ value: String) -> [String] {
        value.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    }

    private static func normalize(_ value: String) -> String {
        value.lowercased().trimmingCharacters(in: .punctuationCharacters)
    }
}
