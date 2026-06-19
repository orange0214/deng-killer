from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field


class ClaimType(str, Enum):
    technical_fact = "technical_fact"
    business_fact = "business_fact"
    civic_fact = "civic_fact"
    subjective = "subjective"
    unknown = "unknown"


class VerificationVerdict(str, Enum):
    likely_true = "likely_true"
    possibly_false = "possibly_false"
    uncertain = "uncertain"
    needs_context = "needs_context"
    controversial = "controversial"


class StrictBaseModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class HealthResponse(StrictBaseModel):
    status: str


class VerificationRequest(StrictBaseModel):
    claim: str = Field(..., min_length=1, max_length=1000)
    minimal_context: Optional[str] = Field(default=None, max_length=1200)
    language: str = Field(default="zh-Hans", min_length=2, max_length=32)
    domain: ClaimType = ClaimType.unknown


class VerificationResult(StrictBaseModel):
    original_claim: str
    verdict: VerificationVerdict
    confidence: float = Field(..., ge=0.0, le=1.0)
    issue: str
    correction: str
    evidence_summary: List[str] = Field(..., min_length=1)
