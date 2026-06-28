from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_health():
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_verify_claim_matches_frontend_contract():
    response = client.post(
        "/v1/claims/verify",
        json={
            "claim": "Redis 是关系型数据库。",
            "minimal_context": "Redis 是关系型数据库。",
            "language": "zh-Hans",
            "domain": "technical_fact",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["original_claim"] == "Redis 是关系型数据库。"
    assert body["verdict"] == "possibly_false"
    assert body["confidence"] == 0.9
    assert body["evidence_summary"]


def test_verify_fastapi_claim_returns_possibly_false_with_evidence():
    response = client.post(
        "/v1/claims/verify",
        json={
            "claim": "FastAPI 比 Django 快是因为 FastAPI 是多线程。",
            "minimal_context": "FastAPI 比 Django 快是因为 FastAPI 是多线程。",
            "language": "zh-Hans",
            "domain": "technical_fact",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["verdict"] == "possibly_false"
    assert body["evidence_summary"]


def test_verify_unknown_claim_returns_needs_context():
    response = client.post(
        "/v1/claims/verify",
        json={
            "claim": "这个技术肯定更高级。",
            "minimal_context": "这个技术肯定更高级。",
            "language": "zh-Hans",
            "domain": "unknown",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["verdict"] == "needs_context"
    assert body["confidence"] < 0.5


def test_verify_rejects_full_conversation_payload():
    response = client.post(
        "/v1/claims/verify",
        json={
            "claim": "Redis 是关系型数据库。",
            "minimal_context": "Redis 是关系型数据库。",
            "conversation_history": ["我昨天还聊了很多私人内容。"],
            "language": "zh-Hans",
            "domain": "technical_fact",
        },
    )

    assert response.status_code == 400
    assert "disallowed private context" in response.json()["detail"]


def test_verify_rejects_unknown_extra_field():
    response = client.post(
        "/v1/claims/verify",
        json={
            "claim": "Redis 是关系型数据库。",
            "minimal_context": "Redis 是关系型数据库。",
            "unexpected": "not allowed",
            "language": "zh-Hans",
            "domain": "technical_fact",
        },
    )

    assert response.status_code == 422
