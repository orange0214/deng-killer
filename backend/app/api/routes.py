from typing import Any

from fastapi import APIRouter, HTTPException, Request, status
from pydantic import ValidationError

from app.privacy.payload_guard import PrivacyPayloadError, validate_privacy_payload
from app.schemas.verification import HealthResponse, VerificationRequest, VerificationResult
from app.services.verifier import RuleBasedVerificationService

router = APIRouter()
verification_service = RuleBasedVerificationService()


@router.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse(status="ok")


@router.post("/v1/claims/verify", response_model=VerificationResult)
async def verify_claim(request: Request) -> VerificationResult:
    payload: Any = await request.json()

    try:
        validate_privacy_payload(payload)
        verification_request = VerificationRequest.model_validate(payload)
    except PrivacyPayloadError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
    except ValidationError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=exc.errors(),
        ) from exc

    return verification_service.verify(verification_request)
