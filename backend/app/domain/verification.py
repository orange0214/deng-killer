from dataclasses import dataclass
from enum import Enum
from typing import List, Optional


class EvidenceStance(str, Enum):
    supports = "supports"
    contradicts = "contradicts"
    insufficient = "insufficient"
    needs_context = "needs_context"


@dataclass(frozen=True)
class AtomicClaim:
    text: str
    focus: str = "claim"


@dataclass(frozen=True)
class EvidenceItem:
    summary: str
    stance: EvidenceStance
    source_name: str = "fixture"
    correction_hint: Optional[str] = None


@dataclass(frozen=True)
class EvidenceJudgement:
    atomic_claim: AtomicClaim
    stance: EvidenceStance
    issue: str
    confidence: float
    evidence_items: List[EvidenceItem]
    correction_hint: Optional[str] = None


@dataclass(frozen=True)
class PipelineResult:
    original_claim: str
    judgements: List[EvidenceJudgement]
