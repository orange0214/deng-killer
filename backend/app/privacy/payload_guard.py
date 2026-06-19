from typing import Any, Iterable


class PrivacyPayloadError(ValueError):
    """Raised when a request attempts to send disallowed private context."""


FORBIDDEN_KEYS = {
    "audio",
    "audio_data",
    "audio_file",
    "audio_url",
    "full_audio",
    "transcript",
    "full_transcript",
    "transcripts",
    "transcript_segments",
    "sentences",
    "conversation",
    "conversation_history",
    "full_conversation",
    "messages",
    "speaker_history",
    "speakers",
}


def validate_privacy_payload(payload: Any) -> None:
    if not isinstance(payload, dict):
        raise PrivacyPayloadError("Request body must be a JSON object for one claim.")

    forbidden = sorted(_find_forbidden_keys(payload))
    if forbidden:
        joined = ", ".join(forbidden)
        raise PrivacyPayloadError(
            f"Payload includes disallowed private context fields: {joined}."
        )


def _find_forbidden_keys(value: Any) -> Iterable[str]:
    if isinstance(value, dict):
        for key, nested_value in value.items():
            normalized_key = str(key).lower()
            if normalized_key in FORBIDDEN_KEYS:
                yield str(key)
            yield from _find_forbidden_keys(nested_value)
    elif isinstance(value, list):
        for item in value:
            yield from _find_forbidden_keys(item)
