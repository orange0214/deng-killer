from app.domain.verification import (
    AtomicClaim,
    EvidenceItem,
    EvidenceJudgement,
    EvidenceStance,
    PipelineResult,
)
from app.schemas.verification import (
    ClaimType,
    VerificationRequest,
    VerificationVerdict,
)
from app.services.pipeline import VerificationPipeline
from app.services.verdict_generator import VerdictGenerator


def test_contradiction_generates_possibly_false():
    result = VerificationPipeline().verify(
        VerificationRequest(
            claim="Redis 是关系型数据库。",
            minimal_context="Redis 是关系型数据库。",
            domain=ClaimType.technical_fact,
        )
    )

    assert result.verdict == VerificationVerdict.possibly_false
    assert 0.7 <= result.confidence <= 1.0
    assert result.evidence_summary


def test_insufficient_generates_low_confidence_needs_context():
    result = VerificationPipeline().verify(
        VerificationRequest(
            claim="这个技术肯定更高级。",
            minimal_context="这个技术肯定更高级。",
            domain=ClaimType.unknown,
        )
    )

    assert result.verdict == VerificationVerdict.needs_context
    assert result.confidence < 0.5


def test_mixed_atomic_claims_can_summarize_causal_error():
    result = VerificationPipeline().verify(
        VerificationRequest(
            claim="FastAPI 比 Django 快是因为 FastAPI 是多线程。",
            minimal_context="FastAPI 比 Django 快是因为 FastAPI 是多线程。",
            domain=ClaimType.technical_fact,
        )
    )

    assert result.verdict == VerificationVerdict.possibly_false
    assert result.confidence == 0.82
    assert "归因于多线程" in result.issue
    assert "FastAPI 基于 Starlette，并支持 ASGI。" in result.evidence_summary


def test_civic_fact_result_stays_evidence_limited_without_decision_advice():
    result = VerificationPipeline().verify(
        VerificationRequest(
            claim="美国总统任期是 5 年。",
            minimal_context="美国总统任期是 5 年。",
            domain=ClaimType.civic_fact,
        )
    )

    assert result.verdict == VerificationVerdict.possibly_false
    assert "美国总统单届任期不是 5 年" in result.issue
    combined_text = " ".join(
        [result.issue, result.correction, *result.evidence_summary]
    )
    assert "建议你" not in combined_text
    assert "应该投票" not in combined_text


def test_generic_contradiction_uses_judgement_summary():
    atomic_claim = AtomicClaim(text="测试 claim")
    judgement = EvidenceJudgement(
        atomic_claim=atomic_claim,
        stance=EvidenceStance.contradicts,
        issue="证据不一致。",
        confidence=0.76,
        evidence_items=[
            EvidenceItem(
                summary="测试证据。",
                stance=EvidenceStance.contradicts,
                correction_hint="更准确的测试说法。",
            )
        ],
    )

    result = VerdictGenerator().generate(
        VerificationRequest(claim="测试 claim", minimal_context=None),
        PipelineResult(original_claim="测试 claim", judgements=[judgement]),
    )

    assert result.verdict == VerificationVerdict.possibly_false
    assert result.confidence == 0.76
    assert result.correction == "更准确的测试说法。"
    assert result.evidence_summary == ["测试证据。"]
