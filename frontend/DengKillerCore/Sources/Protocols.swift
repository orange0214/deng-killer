import Foundation

public protocol VerificationClient: Sendable {
    func verify(_ request: VerificationRequest) async throws -> VerificationResult
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

