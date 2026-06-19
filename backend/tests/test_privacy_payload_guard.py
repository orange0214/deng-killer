import pytest

from app.privacy.payload_guard import PrivacyPayloadError, validate_privacy_payload


def test_allows_single_claim_with_minimal_context():
    validate_privacy_payload(
        {
            "claim": "Redis 是关系型数据库。",
            "minimal_context": "Redis 是关系型数据库。",
            "language": "zh-Hans",
            "domain": "technical_fact",
        }
    )


def test_rejects_full_transcript_payload():
    with pytest.raises(PrivacyPayloadError):
        validate_privacy_payload(
            {
                "claim": "Redis 是关系型数据库。",
                "full_transcript": "这里是一整段私人对话。",
                "language": "zh-Hans",
                "domain": "technical_fact",
            }
        )
