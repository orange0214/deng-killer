import Combine
import Foundation

@MainActor
public final class ConversationViewModel: ObservableObject {
    @Published public private(set) var isRecording = false
    @Published public private(set) var partialTranscript = ""
    @Published public private(set) var sentences: [TranscriptSentence] = []
    @Published public private(set) var claims: [ClaimAssessment] = []
    @Published public var errorMessage: String?

    private let verificationClient: VerificationClient
    private let store: ConversationStore
    private let scorer: ClaimScorer
    private let simulationDelayNanoseconds: UInt64

    public init(
        verificationClient: VerificationClient,
        store: ConversationStore = InMemoryConversationStore(),
        scorer: ClaimScorer = ClaimScorer(),
        simulationDelayNanoseconds: UInt64 = 250_000_000
    ) {
        self.verificationClient = verificationClient
        self.store = store
        self.scorer = scorer
        self.simulationDelayNanoseconds = simulationDelayNanoseconds
    }

    public var immediateResults: [ClaimAssessment] {
        claims.filter { $0.status != .ignored && $0.status != .reviewLater }
    }

    public var reviewClaims: [ClaimAssessment] {
        claims.filter { $0.status == .reviewLater || $0.status == .uncertain || $0.status == .needsContext }
    }

    public func startSimulation() {
        guard !isRecording else { return }
        reset()
        isRecording = true

        Task {
            for sentence in Self.demoTranscript {
                guard !Task.isCancelled, isRecording else { break }
                await process(sentence)
                try? await Task.sleep(nanoseconds: simulationDelayNanoseconds)
            }
            isRecording = false
            partialTranscript = ""
        }
    }

    public func stopSimulation() {
        isRecording = false
        partialTranscript = ""
    }

    public func reset() {
        isRecording = false
        partialTranscript = ""
        sentences = []
        claims = []
        errorMessage = nil
        store.clear()
    }

    public func process(_ sentence: TranscriptSentence) async {
        if !sentence.isFinal {
            partialTranscript = sentence.text
            return
        }

        partialTranscript = ""
        sentences.append(sentence)
        store.save(sentence: sentence)

        var assessment = scorer.assess(sentence: sentence)
        claims.append(assessment)
        store.save(claim: assessment)

        guard assessment.status == .verifying else { return }

        do {
            let request = VerificationRequest(
                claim: assessment.claim,
                minimalContext: sentence.text,
                domain: assessment.claimType
            )
            let result = try await verificationClient.verify(request)
            assessment.result = result
            assessment.status = status(for: result.verdict)
            update(assessment)
        } catch {
            assessment.status = .failed
            update(assessment)
            errorMessage = "核验服务暂时不可用，已保留该主张，可稍后重试。"
        }
    }

    public func retryFailedClaims() {
        let failedClaims = claims.filter { $0.status == .failed }
        guard !failedClaims.isEmpty else { return }

        Task {
            for claim in failedClaims {
                await retry(claim)
            }
        }
    }

    private func retry(_ claim: ClaimAssessment) async {
        var retryingClaim = claim
        retryingClaim.status = .verifying
        update(retryingClaim)

        do {
            let request = VerificationRequest(
                claim: retryingClaim.claim,
                minimalContext: retryingClaim.claim,
                domain: retryingClaim.claimType
            )
            let result = try await verificationClient.verify(request)
            retryingClaim.result = result
            retryingClaim.status = status(for: result.verdict)
            update(retryingClaim)
            errorMessage = nil
        } catch {
            retryingClaim.status = .failed
            update(retryingClaim)
            errorMessage = "重试失败，请稍后再试。"
        }
    }

    private func update(_ assessment: ClaimAssessment) {
        guard let index = claims.firstIndex(where: { $0.id == assessment.id }) else { return }
        claims[index] = assessment
        store.update(claim: assessment)
    }

    private func status(for verdict: VerificationVerdict) -> ClaimStatus {
        switch verdict {
        case .likelyTrue:
            return .likelyTrue
        case .possiblyFalse:
            return .possiblyFalse
        case .uncertain:
            return .uncertain
        case .needsContext:
            return .needsContext
        case .controversial:
            return .uncertain
        }
    }

    public static let demoTranscript: [TranscriptSentence] = [
        TranscriptSentence(speaker: "A", startTime: "00:00:01", endTime: "00:00:03", text: "我觉得 Python 写起来更舒服。", isFinal: false),
        TranscriptSentence(speaker: "A", startTime: "00:00:01", endTime: "00:00:04", text: "我觉得 Python 写起来更舒服。", isFinal: true),
        TranscriptSentence(speaker: "A", startTime: "00:00:05", endTime: "00:00:10", text: "FastAPI 比 Django 快是因为 FastAPI 是多线程。", isFinal: true),
        TranscriptSentence(speaker: "B", startTime: "00:00:11", endTime: "00:00:14", text: "某公司去年利润增长了 30%。", isFinal: true),
        TranscriptSentence(speaker: "A", startTime: "00:00:15", endTime: "00:00:18", text: "Redis 是关系型数据库。", isFinal: true),
        TranscriptSentence(speaker: "B", startTime: "00:00:19", endTime: "00:00:22", text: "美国总统任期是 5 年。", isFinal: true)
    ]
}

