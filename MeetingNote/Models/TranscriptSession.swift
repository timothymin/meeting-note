import Foundation

struct TranscriptSession: Sendable {
    let id: UUID
    let title: String
    let startedAt: Date
    let endedAt: Date
    let text: String
    let model: String
    let language: String?
    let contextPrompt: String

    var duration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }
}
