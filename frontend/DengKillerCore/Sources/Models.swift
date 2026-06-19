import Foundation

public struct TranscriptSentence: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let speaker: String
    public let startTime: String
    public let endTime: String
    public let text: String
    public let isFinal: Bool

    public init(
        id: UUID = UUID(),
        speaker: String,
        startTime: String,
        endTime: String,
        text: String,
        isFinal: Bool
    ) {
        self.id = id
        self.speaker = speaker
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
        self.isFinal = isFinal
    }
}

public enum ClaimType: String, Equatable, Sendable {
    case technicalFact = "technical_fact"
    case businessFact = "business_fact"
    case civicFact = "civic_fact"
    case subjective = "subjective"
    case unknown
}

public enum ClaimImportance: String, Equatable, Sendable {
    case low
    case medium
    case high
}

public enum ClaimStatus: String, Equatable, Sendable {
    case ignored
    case reviewLater
    case verifying
    case possiblyFalse
    case uncertain
    case needsContext
    case likelyTrue
    case failed
}

public enum VerificationVerdict: String, Equatable, Sendable {
    case likelyTrue = "likely_true"
    case possiblyFalse = "possibly_false"
    case uncertain
    case needsContext = "needs_context"
    case controversial
}

public struct ClaimAssessment: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let claim: String
    public let claimType: ClaimType
    public let importance: ClaimImportance
    public let checkworthyScore: Double
    public let reason: String
    public var status: ClaimStatus
    public var result: VerificationResult?

    public init(
        id: UUID = UUID(),
        claim: String,
        claimType: ClaimType,
        importance: ClaimImportance,
        checkworthyScore: Double,
        reason: String,
        status: ClaimStatus,
        result: VerificationResult? = nil
    ) {
        self.id = id
        self.claim = claim
        self.claimType = claimType
        self.importance = importance
        self.checkworthyScore = checkworthyScore
        self.reason = reason
        self.status = status
        self.result = result
    }
}

public struct VerificationRequest: Equatable, Sendable {
    public let claim: String
    public let minimalContext: String?
    public let language: String
    public let domain: ClaimType

    public init(
        claim: String,
        minimalContext: String?,
        language: String = "zh-Hans",
        domain: ClaimType
    ) {
        self.claim = claim
        self.minimalContext = minimalContext
        self.language = language
        self.domain = domain
    }
}

public struct VerificationResult: Equatable, Sendable {
    public let originalClaim: String
    public let verdict: VerificationVerdict
    public let confidence: Double
    public let issue: String
    public let correction: String
    public let evidenceSummary: [String]

    public init(
        originalClaim: String,
        verdict: VerificationVerdict,
        confidence: Double,
        issue: String,
        correction: String,
        evidenceSummary: [String]
    ) {
        self.originalClaim = originalClaim
        self.verdict = verdict
        self.confidence = confidence
        self.issue = issue
        self.correction = correction
        self.evidenceSummary = evidenceSummary
    }
}
