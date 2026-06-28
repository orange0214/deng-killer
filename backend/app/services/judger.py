from collections import Counter
from typing import List

from app.domain.verification import (
    AtomicClaim,
    EvidenceItem,
    EvidenceJudgement,
    EvidenceStance,
)


class EvidenceJudger:
    """Summarizes retrieved evidence into one stance per atomic claim."""

    def judge(
        self, atomic_claim: AtomicClaim, evidence_items: List[EvidenceItem]
    ) -> EvidenceJudgement:
        if not evidence_items:
            return EvidenceJudgement(
                atomic_claim=atomic_claim,
                stance=EvidenceStance.insufficient,
                issue="当前没有足够证据确认该陈述。",
                confidence=0.38,
                evidence_items=[],
                correction_hint="需要更多主体、时间或数据来源。",
            )

        stance_counts = Counter(item.stance for item in evidence_items)
        stance = stance_counts.most_common(1)[0][0]
        correction_hint = next(
            (item.correction_hint for item in evidence_items if item.correction_hint),
            None,
        )

        if stance == EvidenceStance.contradicts:
            issue = "证据与该原子主张不一致。"
            confidence = 0.82
        elif stance == EvidenceStance.supports:
            issue = "证据支持该原子主张。"
            confidence = 0.72
        elif stance == EvidenceStance.needs_context:
            issue = "该原子主张需要更多上下文才能核验。"
            confidence = 0.46
        else:
            issue = "当前证据不足。"
            confidence = 0.38

        return EvidenceJudgement(
            atomic_claim=atomic_claim,
            stance=stance,
            issue=issue,
            confidence=confidence,
            evidence_items=evidence_items,
            correction_hint=correction_hint,
        )
