import Foundation
import Testing
@testable import MeetingNote

struct TranscriptStoreTests {
    @Test func rendersMarkdownWithFrontMatter() throws {
        let started = Date(timeIntervalSince1970: 1_700_000_000)
        let session = TranscriptSession(
            id: UUID(),
            title: "Weekly sync",
            startedAt: started,
            endedAt: started.addingTimeInterval(90),
            text: "Hello team.",
            model: "tiny",
            language: nil
        )

        let markdown = TranscriptStore().render(session)

        #expect(markdown.contains("title: \"Weekly sync\""))
        #expect(markdown.contains("duration_seconds: 90"))
        #expect(markdown.contains("language: \"auto\""))
        #expect(markdown.contains("# Weekly sync\n\nHello team."))
    }

    @Test func mergesOverlappingLiveChunks() {
        let merged = TranscriptMerger.merge(
            "Today we will review the product launch",
            with: "the product launch and discuss customer feedback"
        )

        #expect(merged == "Today we will review the product launch and discuss customer feedback")
    }
}
