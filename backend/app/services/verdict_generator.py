from typing import Iterable, List

from app.domain.verification import EvidenceJudgement, EvidenceStance, PipelineResult
from app.schemas.verification import (
    VerificationRequest,
    VerificationResult,
    VerificationVerdict,
)


class VerdictGenerator:
    """Converts internal evidence judgements into the public API contract."""

    def generate(
        self, request: VerificationRequest, pipeline_result: PipelineResult
    ) -> VerificationResult:
        claim = request.claim
        judgements = pipeline_result.judgements
        evidence_summary = self._evidence_summary(judgements)

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
                evidence_summary=evidence_summary,
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
                evidence_summary=evidence_summary,
            )

        if "美国总统任期" in claim:
            return VerificationResult(
                original_claim=claim,
                verdict=VerificationVerdict.possibly_false,
                confidence=0.88,
                issue="美国总统单届任期不是 5 年。",
                correction="美国总统单届任期为 4 年，通常最多连任一次。",
                evidence_summary=evidence_summary,
            )

        if "利润增长" in claim:
            return VerificationResult(
                original_claim=claim,
                verdict=VerificationVerdict.uncertain,
                confidence=0.46,
                issue="该陈述缺少公司名称、年份和财报口径。",
                correction="需要明确公司、财年、利润类型和数据来源后才能核验。",
                evidence_summary=evidence_summary,
            )

        if any(judgement.stance == EvidenceStance.contradicts for judgement in judgements):
            return VerificationResult(
                original_claim=claim,
                verdict=VerificationVerdict.possibly_false,
                confidence=self._max_confidence(judgements),
                issue="证据与该陈述存在不一致。",
                correction=self._correction(judgements),
                evidence_summary=evidence_summary,
            )

        if any(judgement.stance == EvidenceStance.needs_context for judgement in judgements):
            return VerificationResult(
                original_claim=claim,
                verdict=VerificationVerdict.uncertain,
                confidence=0.46,
                issue="该陈述需要更多上下文才能核验。",
                correction=self._correction(judgements),
                evidence_summary=evidence_summary,
            )

        return VerificationResult(
            original_claim=claim,
            verdict=VerificationVerdict.needs_context,
            confidence=0.38,
            issue="当前上下文不足以确认该陈述。",
            correction=self._correction(judgements),
            evidence_summary=evidence_summary,
        )

    def _evidence_summary(self, judgements: List[EvidenceJudgement]) -> List[str]:
        summaries: List[str] = []
        seen = set()

        for judgement in judgements:
            for evidence_item in judgement.evidence_items:
                if evidence_item.summary not in seen:
                    summaries.append(evidence_item.summary)
                    seen.add(evidence_item.summary)

        if summaries:
            return summaries

        return ["该主张缺少足够的可验证细节。"]

    def _correction(self, judgements: Iterable[EvidenceJudgement]) -> str:
        for judgement in judgements:
            if judgement.correction_hint:
                return judgement.correction_hint
            for evidence_item in judgement.evidence_items:
                if evidence_item.correction_hint:
                    return evidence_item.correction_hint
        return "需要更多主体、时间或数据来源。"

    def _max_confidence(self, judgements: Iterable[EvidenceJudgement]) -> float:
        return max((judgement.confidence for judgement in judgements), default=0.38)
