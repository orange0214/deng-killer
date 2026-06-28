from typing import Optional

from app.schemas.verification import VerificationRequest, VerificationResult
from app.services.pipeline import VerificationPipeline


class RuleBasedVerificationService:
    """Backward-compatible wrapper around the verification pipeline."""

    def __init__(self, pipeline: Optional[VerificationPipeline] = None) -> None:
        self.pipeline = pipeline or VerificationPipeline()

    def verify(self, request: VerificationRequest) -> VerificationResult:
        return self.pipeline.verify(request)
