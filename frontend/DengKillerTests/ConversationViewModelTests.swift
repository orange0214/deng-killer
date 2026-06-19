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

