from typing import List

from app.domain.verification import AtomicClaim, EvidenceItem, EvidenceStance


class InMemoryEvidenceRetriever:
    """Fixture-backed retriever used until real search or RAG is introduced."""

    def retrieve(self, atomic_claim: AtomicClaim) -> List[EvidenceItem]:
        text = atomic_claim.text

        if "FastAPI" in text and "多线程" in text:
            return [
                EvidenceItem(
                    summary="FastAPI 基于 Starlette，并支持 ASGI。",
                    stance=EvidenceStance.contradicts,
                    source_name="FastAPI fixture",
                    correction_hint=(
                        "FastAPI 的性能优势通常主要来自 ASGI、Starlette 和 "
                        "async/await 异步处理，而不是框架本身是多线程。"
                    ),
                ),
                EvidenceItem(
                    summary="FastAPI 支持 async/await 异步请求处理。",
                    stance=EvidenceStance.contradicts,
                    source_name="FastAPI fixture",
                ),
                EvidenceItem(
                    summary="多线程更多与部署服务器或运行环境有关，不是 FastAPI 的核心设计原因。",
                    stance=EvidenceStance.contradicts,
                    source_name="FastAPI fixture",
                ),
            ]

        if "FastAPI" in text and "Django" in text:
            return [
                EvidenceItem(
                    summary="FastAPI 在某些高并发 I/O 场景下表现较好。",
                    stance=EvidenceStance.supports,
                    source_name="FastAPI fixture",
                )
            ]

        if "Redis" in text:
            return [
                EvidenceItem(
                    summary="Redis 的核心数据模型是键值与多种数据结构。",
                    stance=EvidenceStance.contradicts,
                    source_name="Redis fixture",
                    correction_hint=(
                        "更准确的说法是：Redis 是内存数据结构存储，常被用作缓存、"
                        "消息代理或键值数据库。"
                    ),
                ),
                EvidenceItem(
                    summary="关系型数据库通常以表、行、列和关系约束组织数据。",
                    stance=EvidenceStance.contradicts,
                    source_name="Redis fixture",
                ),
            ]

        if "美国总统任期" in text:
            return [
                EvidenceItem(
                    summary="美国总统任期按四年一届计算。",
                    stance=EvidenceStance.contradicts,
                    source_name="Civic fixture",
                    correction_hint="美国总统单届任期为 4 年，通常最多连任一次。",
                ),
                EvidenceItem(
                    summary="任期限制来自美国宪法第二十二修正案。",
                    stance=EvidenceStance.contradicts,
                    source_name="Civic fixture",
                ),
            ]

        if "利润增长" in text:
            return [
                EvidenceItem(
                    summary="时间和主体不完整会导致无法定位可靠财报来源。",
                    stance=EvidenceStance.needs_context,
                    source_name="Business fixture",
                    correction_hint="需要明确公司、财年、利润类型和数据来源后才能核验。",
                ),
                EvidenceItem(
                    summary="利润增长可能指净利润、经营利润或调整后利润。",
                    stance=EvidenceStance.needs_context,
                    source_name="Business fixture",
                ),
            ]

        return []
