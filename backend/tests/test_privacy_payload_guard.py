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


@pytest.mark.parametrize("field", ["audio", "messages", "speaker_history"])
def test_rejects_forbidden_top_level_private_fields(field):
    with pytest.raises(PrivacyPayloadError):
        validate_privacy_payload(
            {
                "claim": "Redis 是关系型数据库。",
                field: "private content",
                "language": "zh-Hans",
                "domain": "technical_fact",
            }
        )


def test_rejects_nested_private_fields():
    with pytest.raises(PrivacyPayloadError):
        validate_privacy_payload(
            {
                "claim": "Redis 是关系型数据库。",
                "metadata": {
                    "debug": {
                        "messages": ["这里是一整段私人对话。"],
                    }
                },
                "language": "zh-Hans",
                "domain": "technical_fact",
            }
        )
