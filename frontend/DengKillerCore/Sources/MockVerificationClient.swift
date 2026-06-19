import Foundation

public enum MockVerificationError: Error, Equatable {
    case forcedFailure
}

public actor MockVerificationClient: VerificationClient {
    public private(set) var capturedRequests: [VerificationRequest] = []
    private var shouldFailNextRequest: Bool

    public init(shouldFailNextRequest: Bool = false) {
        self.shouldFailNextRequest = shouldFailNextRequest
    }

    public func failNextRequest() {
        shouldFailNextRequest = true
    }

    public func verify(_ request: VerificationRequest) async throws -> VerificationResult {
        capturedRequests.append(request)

        if shouldFailNextRequest {
            shouldFailNextRequest = false
            throw MockVerificationError.forcedFailure
        }

        if request.claim.contains("FastAPI") {
            return VerificationResult(
                originalClaim: request.claim,
                verdict: .possiblyFalse,
                confidence: 0.82,
                issue: "该陈述将 FastAPI 的性能优势归因于多线程，原因不准确。",
                correction: "FastAPI 在某些高并发 I/O 场景下表现较好，主要原因通常与 ASGI、Starlette 和 async/await 异步处理有关。",
                evidenceSummary: [
                    "FastAPI 基于 Starlette，并支持 ASGI。",
                    "FastAPI 支持 async/await 异步请求处理。",
                    "多线程更多与部署服务器或运行环境有关，不是 FastAPI 的核心设计原因。"
                ],
                suggestedResponse: "你说的多线程是指部署方式，还是 FastAPI 框架本身？我理解 FastAPI 的优势主要是 ASGI 和异步 I/O。"
            )
        }

        if request.claim.contains("Redis") {
            return VerificationResult(
                originalClaim: request.claim,
                verdict: .possiblyFalse,
                confidence: 0.9,
                issue: "Redis 通常被归类为内存键值数据库，而不是关系型数据库。",
                correction: "更准确的说法是：Redis 是内存数据结构存储，常被用作缓存、消息代理或键值数据库。",
                evidenceSummary: [
                    "Redis 的核心数据模型是键值与多种数据结构。",
                    "关系型数据库通常以表、行、列和关系约束组织数据。"
                ],
                suggestedResponse: "你这里说的关系型，是指它能存结构化数据，还是指传统表关系模型？"
            )
        }

        if request.claim.contains("美国总统任期") {
            return VerificationResult(
                originalClaim: request.claim,
                verdict: .possiblyFalse,
                confidence: 0.88,
                issue: "美国总统单届任期不是 5 年。",
                correction: "美国总统单届任期为 4 年，通常最多连任一次。",
                evidenceSummary: [
                    "美国总统任期按四年一届计算。",
                    "任期限制来自美国宪法第二十二修正案。"
                ],
                suggestedResponse: "我印象里美国总统是一届 4 年，我们要不要确认一下这个数字？"
            )
        }

        if request.claim.contains("利润增长") {
            return VerificationResult(
                originalClaim: request.claim,
                verdict: .uncertain,
                confidence: 0.46,
                issue: "该陈述缺少公司名称、年份和财报口径。",
                correction: "需要明确公司、财年、利润类型和数据来源后才能核验。",
                evidenceSummary: [
                    "时间和主体不完整会导致无法定位可靠财报来源。",
                    "利润增长可能指净利润、经营利润或调整后利润。"
                ],
                suggestedResponse: "这里说的是哪家公司、哪一年的利润？看财报口径会更准确。"
            )
        }

        return VerificationResult(
            originalClaim: request.claim,
            verdict: .needsContext,
            confidence: 0.38,
            issue: "当前上下文不足以确认该陈述。",
            correction: "需要更多主体、时间或数据来源。",
            evidenceSummary: [
                "该主张缺少足够的可验证细节。"
            ],
            suggestedResponse: "这个说法可能需要看具体场景，你指的是哪个时间或来源？"
        )
    }
}

