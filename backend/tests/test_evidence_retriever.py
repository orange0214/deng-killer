from app.domain.verification import AtomicClaim
from app.services.retriever import InMemoryEvidenceRetriever


def test_redis_claim_retrieves_fixture_evidence():
    evidence = InMemoryEvidenceRetriever().retrieve(
        AtomicClaim(text="Redis 是关系型数据库。")
    )

    assert [item.summary for item in evidence] == [
        "Redis 的核心数据模型是键值与多种数据结构。",
        "关系型数据库通常以表、行、列和关系约束组织数据。",
    ]


def test_fastapi_causal_claim_retrieves_async_evidence():
    evidence = InMemoryEvidenceRetriever().retrieve(
        AtomicClaim(text="FastAPI 快的原因是它是多线程。")
    )

    summaries = [item.summary for item in evidence]
    assert "FastAPI 基于 Starlette，并支持 ASGI。" in summaries
    assert "FastAPI 支持 async/await 异步请求处理。" in summaries


def test_unknown_claim_retrieves_no_evidence():
    evidence = InMemoryEvidenceRetriever().retrieve(
        AtomicClaim(text="这个技术肯定更高级。")
    )

    assert evidence == []
