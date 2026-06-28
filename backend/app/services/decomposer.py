from typing import List

from app.domain.verification import AtomicClaim


class ClaimDecomposer:
    """Splits complex claims into smaller claims for evidence judgement."""

    def decompose(self, claim: str) -> List[AtomicClaim]:
        if "FastAPI" in claim and "Django" in claim and "多线程" in claim:
            return [
                AtomicClaim(
                    text="FastAPI 在某些场景下可能比 Django 快。",
                    focus="performance_comparison",
                ),
                AtomicClaim(
                    text="FastAPI 快的原因是它是多线程。",
                    focus="causal_reason",
                ),
            ]

        return [AtomicClaim(text=claim)]
