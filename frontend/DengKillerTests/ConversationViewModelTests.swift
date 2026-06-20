import XCTest
@testable import DengKillerCore

@MainActor
final class ConversationViewModelTests: XCTestCase {
    func testPartialSentenceDoesNotTriggerClaimProcessing() async {
        let client = MockVerificationClient()
        let viewModel = ConversationViewModel(
            verificationClient: client,
            simulationDelayNanoseconds: 0
        )

        await viewModel.process(
            TranscriptSentence(
                speaker: "A",
                startTime: "00:00:01",
                endTime: "00:00:02",
                text: "FastAPI 比 Django",
                isFinal: false
            )
        )

        XCTAssertEqual(viewModel.partialTranscript, "FastAPI 比 Django")
        XCTAssertTrue(viewModel.sentences.isEmpty)
        XCTAssertTrue(viewModel.claims.isEmpty)
        let requests = await client.capturedRequests
        XCTAssertTrue(requests.isEmpty)
    }

    func testRecordingPartialEventDoesNotTriggerClaimProcessing() async {
        let client = MockVerificationClient()
        let service = MockAudioTranscriptionService(
            events: [
                .partial("Redis 是"),
                .final(.init(speaker: "A", startTime: "00:00", endTime: "00:01", text: "Redis 是关系型数据库。", isFinal: true))
            ],
            delayNanoseconds: 100_000_000
        )
        let viewModel = ConversationViewModel(
            verificationClient: client,
            transcriptionService: service,
            simulationDelayNanoseconds: 0
        )

        viewModel.startRecording()
        try? await Task.sleep(nanoseconds: 150_000_000)

        XCTAssertEqual(viewModel.partialTranscript, "Redis 是")
        XCTAssertTrue(viewModel.sentences.isEmpty)
        XCTAssertTrue(viewModel.claims.isEmpty)
        let requests = await client.capturedRequests
        XCTAssertTrue(requests.isEmpty)
    }

    func testRecordingFinalEventEntersClaimPipeline() async {
        let client = MockVerificationClient()
        let service = MockAudioTranscriptionService(
            events: [
                .partial("Redis 是关系型"),
                .final(.init(speaker: "A", startTime: "00:00", endTime: "00:02", text: "Redis 是关系型数据库。", isFinal: true))
            ]
        )
        let viewModel = ConversationViewModel(
            verificationClient: client,
            transcriptionService: service,
            simulationDelayNanoseconds: 0
        )

        viewModel.startRecording()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.sentences.count, 1)
        XCTAssertEqual(viewModel.claims.first?.status, .possiblyFalse)
        let requests = await client.capturedRequests
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.claim, "Redis 是关系型数据库。")
    }

    func testRecordingFailureShowsErrorWithoutClearingTranscript() async {
        let client = MockVerificationClient()
        let existingSentence = TranscriptSentence(speaker: "A", startTime: "1", endTime: "2", text: "某公司去年利润增长了 30%。", isFinal: true)
        let service = MockAudioTranscriptionService(
            events: [
                .final(existingSentence),
                .failed("语音识别中断，请重新开始记录。")
            ]
        )
        let viewModel = ConversationViewModel(
            verificationClient: client,
            transcriptionService: service,
            simulationDelayNanoseconds: 0
        )

        viewModel.startRecording()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.sentences, [existingSentence])
        XCTAssertEqual(viewModel.errorMessage, "语音识别中断，请重新开始记录。")
        XCTAssertFalse(viewModel.isRecording)
    }

    func testSentenceFinalizerFinalizesChineseAndEnglishPunctuation() {
        var finalizer = SentenceFinalizer(startDate: Date(timeIntervalSince1970: 0))

        let events = finalizer.ingest("Redis 是关系型数据库。FastAPI is threaded?", isFinal: false, now: Date(timeIntervalSince1970: 3))
        let finalTexts = events.compactMap { event -> String? in
            if case let .final(sentence) = event {
                return sentence.text
            }
            return nil
        }

        XCTAssertEqual(finalTexts, ["Redis 是关系型数据库。", "FastAPI is threaded?"])
    }

    func testSentenceFinalizerKeepsRemainderPartialAndForceFinalizesWithoutPunctuation() {
        var finalizer = SentenceFinalizer(startDate: Date(timeIntervalSince1970: 0))

        let partialEvents = finalizer.ingest("FastAPI 比 Django", isFinal: false, now: Date(timeIntervalSince1970: 1))
        XCTAssertEqual(partialEvents, [.partial("FastAPI 比 Django")])

        let finalEvents = finalizer.ingest("FastAPI 比 Django", isFinal: true, now: Date(timeIntervalSince1970: 2))
        guard case let .final(sentence) = finalEvents.first else {
            XCTFail("Expected a finalized sentence")
            return
        }
        XCTAssertEqual(finalEvents.count, 1)
        XCTAssertEqual(sentence.speaker, "A")
        XCTAssertEqual(sentence.startTime, "00:02")
        XCTAssertEqual(sentence.endTime, "00:03")
        XCTAssertEqual(sentence.text, "FastAPI 比 Django")
        XCTAssertTrue(sentence.isFinal)
    }

    func testSentenceFinalizerIgnoresEmptyAndDuplicateFinalizedText() {
        var finalizer = SentenceFinalizer()

        XCTAssertTrue(finalizer.ingest("   ", isFinal: false).isEmpty)
        XCTAssertEqual(finalizer.ingest("Redis 是关系型数据库。", isFinal: false).count, 1)
        XCTAssertTrue(finalizer.ingest("Redis 是关系型数据库。", isFinal: false).isEmpty)
    }

    func testCheckworthyThresholdsMapToExpectedStates() async {
        let client = MockVerificationClient()
        let viewModel = ConversationViewModel(
            verificationClient: client,
            simulationDelayNanoseconds: 0
        )

        await viewModel.process(.init(speaker: "A", startTime: "1", endTime: "2", text: "我觉得 Python 写起来更舒服。", isFinal: true))
        await viewModel.process(.init(speaker: "A", startTime: "3", endTime: "4", text: "某公司去年利润增长了 30%。", isFinal: true))
        await viewModel.process(.init(speaker: "A", startTime: "5", endTime: "6", text: "Redis 是关系型数据库。", isFinal: true))

        XCTAssertEqual(viewModel.claims[0].status, .ignored)
        XCTAssertEqual(viewModel.claims[1].status, .reviewLater)
        XCTAssertEqual(viewModel.claims[2].status, .possiblyFalse)
        XCTAssertFalse(viewModel.visibleClaims.contains { $0.status == .ignored })
        XCTAssertEqual(viewModel.visibleClaims.count, 2)
        XCTAssertEqual(viewModel.claims[0].checkworthyScore, 0.2, accuracy: 0.001)
        XCTAssertEqual(viewModel.claims[1].checkworthyScore, 0.63, accuracy: 0.001)
        XCTAssertEqual(viewModel.claims[2].checkworthyScore, 0.88, accuracy: 0.001)
    }

    func testMockVerificationReturnsPRDLabels() async throws {
        let client = MockVerificationClient()

        let redis = try await client.verify(.init(claim: "Redis 是关系型数据库。", minimalContext: nil, domain: .technicalFact))
        let company = try await client.verify(.init(claim: "某公司去年利润增长了 30%。", minimalContext: nil, domain: .businessFact))
        let vague = try await client.verify(.init(claim: "这个技术肯定更高级。", minimalContext: nil, domain: .unknown))

        XCTAssertEqual(redis.verdict, .possiblyFalse)
        XCTAssertEqual(company.verdict, .uncertain)
        XCTAssertEqual(vague.verdict, .needsContext)
    }

    func testViewModelReportsFailureAndCanRetry() async {
        let client = MockVerificationClient(shouldFailNextRequest: true)
        let viewModel = ConversationViewModel(
            verificationClient: client,
            simulationDelayNanoseconds: 0
        )

        await viewModel.process(.init(speaker: "A", startTime: "1", endTime: "2", text: "FastAPI 比 Django 快是因为 FastAPI 是多线程。", isFinal: true))

        XCTAssertEqual(viewModel.claims.first?.status, .failed)
        XCTAssertNotNil(viewModel.errorMessage)

        viewModel.retryFailedClaims()
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(viewModel.claims.first?.status, .possiblyFalse)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testPrivacyBoundarySendsOnlySingleClaimAndMinimalContext() async {
        let client = MockVerificationClient()
        let viewModel = ConversationViewModel(
            verificationClient: client,
            simulationDelayNanoseconds: 0
        )

        await viewModel.process(.init(speaker: "A", startTime: "1", endTime: "2", text: "FastAPI 比 Django 快是因为 FastAPI 是多线程。", isFinal: true))
        await viewModel.process(.init(speaker: "B", startTime: "3", endTime: "4", text: "我昨天还聊了很多私人内容。", isFinal: true))

        let requests = await client.capturedRequests
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.claim, "FastAPI 比 Django 快是因为 FastAPI 是多线程。")
        XCTAssertEqual(requests.first?.minimalContext, "FastAPI 比 Django 快是因为 FastAPI 是多线程。")
        XCTAssertFalse(requests.first?.claim.contains("私人内容") ?? true)
    }
}
