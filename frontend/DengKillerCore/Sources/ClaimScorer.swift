import Foundation

public struct ClaimScorer: Sendable {
    public init() {}

    public func assess(sentence: TranscriptSentence) -> ClaimAssessment {
        let text = sentence.text

        if text.contains("我觉得") || text.contains("舒服") || text.contains("不太靠谱") {
            return ClaimAssessment(
                claim: text,
                claimType: .subjective,
                importance: .low,
                checkworthyScore: 0.2,
                reason: "该句更接近主观感受或评价，暂不进入核验。",
                status: .ignored
            )
        }

        if text.contains("FastAPI") {
            return ClaimAssessment(
                claim: text,
                claimType: .technicalFact,
                importance: .medium,
                checkworthyScore: 0.86,
                reason: "该陈述包含明确的技术因果关系，可以通过框架文档和技术资料核验。",
                status: .verifying
            )
        }

        if text.contains("Redis") {
            return ClaimAssessment(
                claim: text,
                claimType: .technicalFact,
                importance: .medium,
                checkworthyScore: 0.88,
                reason: "该陈述包含明确的技术定义，可以通过数据库类型资料核验。",
                status: .verifying
            )
        }

        if text.contains("美国总统任期") {
            return ClaimAssessment(
                claim: text,
                claimType: .civicFact,
                importance: .high,
                checkworthyScore: 0.91,
                reason: "该陈述包含明确制度事实和数量，可以核验。",
                status: .verifying
            )
        }

        if text.contains("利润增长") {
            return ClaimAssessment(
                claim: text,
                claimType: .businessFact,
                importance: .medium,
                checkworthyScore: 0.63,
                reason: "该陈述可能重要，但缺少主体和时间，先进入会后复盘。",
                status: .reviewLater
            )
        }

        return ClaimAssessment(
            claim: text,
            claimType: .unknown,
            importance: .medium,
            checkworthyScore: 0.52,
            reason: "该句可能包含事实信息，但当前可验证性不足。",
            status: .reviewLater
        )
    }
}

