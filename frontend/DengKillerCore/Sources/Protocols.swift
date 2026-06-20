import Foundation

public protocol VerificationClient: Sendable {
    func verify(_ request: VerificationRequest) async throws -> VerificationResult
}

@MainActor
public protocol AudioTranscriptionService: AnyObject {
    func startTranscribing() -> AsyncStream<TranscriptionEvent>
    func stopTranscribing()
}

public protocol ConversationStore: AnyObject {
    var sentences: [TranscriptSentence] { get }
    var claims: [ClaimAssessment] { get }

    func save(sentence: TranscriptSentence)
    func save(claim: ClaimAssessment)
    func update(claim: ClaimAssessment)
    func clear()
}

public final class InMemoryConversationStore: ConversationStore {
    public private(set) var sentences: [TranscriptSentence] = []
    public private(set) var claims: [ClaimAssessment] = []

    public init() {}

    public func save(sentence: TranscriptSentence) {
        sentences.append(sentence)
    }

    public func save(claim: ClaimAssessment) {
        claims.append(claim)
    }

    public func update(claim: ClaimAssessment) {
        guard let index = claims.firstIndex(where: { $0.id == claim.id }) else {
            claims.append(claim)
            return
        }
        claims[index] = claim
    }

    public func clear() {
        sentences.removeAll()
        claims.removeAll()
    }
}

@MainActor
public final class MockAudioTranscriptionService: AudioTranscriptionService {
    private let events: [TranscriptionEvent]
    private let delayNanoseconds: UInt64
    private var continuation: AsyncStream<TranscriptionEvent>.Continuation?
    private var task: Task<Void, Never>?

    public init(events: [TranscriptionEvent], delayNanoseconds: UInt64 = 0) {
        self.events = events
        self.delayNanoseconds = delayNanoseconds
    }

    public func startTranscribing() -> AsyncStream<TranscriptionEvent> {
        let events = events
        let delayNanoseconds = delayNanoseconds

        return AsyncStream { continuation in
            self.continuation = continuation
            self.task = Task {
                for event in events {
                    if delayNanoseconds > 0 {
                        try? await Task.sleep(nanoseconds: delayNanoseconds)
                    }
                    guard !Task.isCancelled else { break }
                    continuation.yield(event)
                }
                continuation.finish()
            }
        }
    }

    public func stopTranscribing() {
        task?.cancel()
        task = nil
        continuation?.finish()
        continuation = nil
    }
}
