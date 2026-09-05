import Foundation

struct TranscriptFile: Identifiable, Hashable, Sendable {
    let url: URL
    let title: String
    let createdAt: Date
    let duration: TimeInterval?
    let preview: String
    let content: String
    let contextPrompt: String

    var id: URL { url }
}
