from app.schemas.verification import (
    VerificationRequest,
    VerificationResult,
    VerificationVerdict,
)


class RuleBasedVerificationService:
    """Temporary verifier that mirrors the Swift mock client for local API work."""

    def verify(self, request: VerificationRequest) -> VerificationResult:
        claim = request.claim

        if "FastAPI" in claim:
            return VerificationResult(
                original_claim=claim,
                verdict=VerificationVerdict.possibly_false,
                confidence=0.82,
                issue="该陈述将 FastAPI 的性能优势归因于多线程，原因不准确。",
                correction=(
                    "FastAPI 在某些高并发 I/O 场景下表现较好，主要原因通常与 "
                    "ASGI、Starlette 和 async/await 异步处理有关。"
                ),
                evidence_summary=[
                    "FastAPI 基于 Starlette，并支持 ASGI。",
                    "FastAPI 支持 async/await 异步请求处理。",
                    "多线程更多与部署服务器或运行环境有关，不是 FastAPI 的核心设计原因。",
                ],
            )

        if "Redis" in claim:
            return VerificationResult(
                original_claim=claim,
                verdict=VerificationVerdict.possibly_false,
                confidence=0.9,
                issue="Redis 通常被归类为内存键值数据库，而不是关系型数据库。",
                correction=(
                    "更准确的说法是：Redis 是内存数据结构存储，常被用作缓存、"
                    "消息代理或键值数据库。"
                ),
                evidence_summary=[
                    "Redis 的核心数据模型是键值与多种数据结构。",
                    "关系型数据库通常以表、行、列和关系约束组织数据。",
                ],
            )

        if "美国总统任期" in claim:
            return VerificationResult(
                original_claim=claim,
                verdict=VerificationVerdict.possibly_false,
                confidence=0.88,
                issue="美国总统单届任期不是 5 年。",
                correction="美国总统单届任期为 4 年，通常最多连任一次。",
                evidence_summary=[
                    "美国总统任期按四年一届计算。",
                    "任期限制来自美国宪法第二十二修正案。",
                ],
            )

        if "利润增长" in claim:
            return VerificationResult(
                original_claim=claim,
                verdict=VerificationVerdict.uncertain,
                confidence=0.46,
                issue="该陈述缺少公司名称、年份和财报口径。",
                correction="需要明确公司、财年、利润类型和数据来源后才能核验。",
                evidence_summary=[
                    "时间和主体不完整会导致无法定位可靠财报来源。",
                    "利润增长可能指净利润、经营利润或调整后利润。",
                ],
            )

        return VerificationResult(
            original_claim=claim,
            verdict=VerificationVerdict.needs_context,
            confidence=0.38,
            issue="当前上下文不足以确认该陈述。",
            correction="需要更多主体、时间或数据来源。",
            evidence_summary=[
                "该主张缺少足够的可验证细节。",
            ],
        )
