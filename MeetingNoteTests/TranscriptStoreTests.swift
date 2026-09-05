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

    @Test func mergesLongRollingContextWithoutDuplicatingIt() {
        let existingWords = (0..<50).map { "word\($0)" }
        let incomingWords = (10..<60).map { "word\($0)" }

        let merged = TranscriptMerger.merge(
            existingWords.joined(separator: " "),
            with: incomingWords.joined(separator: " ")
        )

        #expect(merged == (0..<60).map { "word\($0)" }.joined(separator: " "))
    }

    @Test func toleratesSmallRevisionsInsideRollingContext() {
        let merged = TranscriptMerger.merge(
            "오늘 회의에서는 바이탈 로보틱스의 새로운 로봇 플랫폼을 검토합니다",
            with: "바이탈 로보틱스의 새로운 로봇 플랫폼을 함께 검토합니다 다음 안건은 배포 일정입니다"
        )

        #expect(
            merged
                == "오늘 회의에서는 바이탈 로보틱스의 새로운 로봇 플랫폼을 검토합니다 다음 안건은 배포 일정입니다"
        )
    }
}
