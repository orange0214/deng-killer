from typing import List, Optional

from app.domain.verification import EvidenceJudgement, PipelineResult
from app.schemas.verification import VerificationRequest, VerificationResult
from app.services.decomposer import ClaimDecomposer
from app.services.judger import EvidenceJudger
from app.services.retriever import InMemoryEvidenceRetriever
from app.services.verdict_generator import VerdictGenerator


class VerificationPipeline:
    """Coordinates claim decomposition, retrieval, judgement, and verdicts."""

    def __init__(
        self,
        decomposer: Optional[ClaimDecomposer] = None,
        retriever: Optional[InMemoryEvidenceRetriever] = None,
        judger: Optional[EvidenceJudger] = None,
        verdict_generator: Optional[VerdictGenerator] = None,
    ) -> None:
        self.decomposer = decomposer or ClaimDecomposer()
        self.retriever = retriever or InMemoryEvidenceRetriever()
        self.judger = judger or EvidenceJudger()
        self.verdict_generator = verdict_generator or VerdictGenerator()

    def verify(self, request: VerificationRequest) -> VerificationResult:
        atomic_claims = self.decomposer.decompose(request.claim)
        judgements: List[EvidenceJudgement] = []

        for atomic_claim in atomic_claims:
            evidence_items = self.retriever.retrieve(atomic_claim)
            judgements.append(self.judger.judge(atomic_claim, evidence_items))

        pipeline_result = PipelineResult(
            original_claim=request.claim,
            judgements=judgements,
        )
        return self.verdict_generator.generate(request, pipeline_result)
