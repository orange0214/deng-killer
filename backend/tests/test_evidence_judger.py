from app.domain.verification import AtomicClaim, EvidenceItem, EvidenceStance
from app.services.judger import EvidenceJudger
from app.services.retriever import InMemoryEvidenceRetriever


def test_redis_relational_claim_is_contradicted():
    atomic_claim = AtomicClaim(text="Redis 是关系型数据库。")
    evidence = InMemoryEvidenceRetriever().retrieve(atomic_claim)

    judgement = EvidenceJudger().judge(atomic_claim, evidence)

    assert judgement.stance == EvidenceStance.contradicts
    assert judgement.confidence >= 0.7


def test_fastapi_threading_reason_is_contradicted():
    atomic_claim = AtomicClaim(text="FastAPI 快的原因是它是多线程。")
    evidence = InMemoryEvidenceRetriever().retrieve(atomic_claim)

    judgement = EvidenceJudger().judge(atomic_claim, evidence)

    assert judgement.stance == EvidenceStance.contradicts
    assert "证据与该原子主张不一致" in judgement.issue


def test_profit_growth_claim_needs_context():
    atomic_claim = AtomicClaim(text="某公司去年利润增长了 30%。")
    evidence = InMemoryEvidenceRetriever().retrieve(atomic_claim)

    judgement = EvidenceJudger().judge(atomic_claim, evidence)

    assert judgement.stance == EvidenceStance.needs_context
    assert judgement.confidence < 0.5


def test_empty_evidence_is_insufficient():
    atomic_claim = AtomicClaim(text="这个技术肯定更高级。")

    judgement = EvidenceJudger().judge(atomic_claim, [])

    assert judgement.stance == EvidenceStance.insufficient
    assert judgement.confidence < 0.5


def test_correction_hint_is_carried_from_evidence():
    atomic_claim = AtomicClaim(text="Redis 是关系型数据库。")
    evidence = [
        EvidenceItem(
            summary="Redis 的核心数据模型是键值与多种数据结构。",
            stance=EvidenceStance.contradicts,
            correction_hint="Redis 是内存数据结构存储。",
        )
    ]

    judgement = EvidenceJudger().judge(atomic_claim, evidence)

    assert judgement.correction_hint == "Redis 是内存数据结构存储。"
