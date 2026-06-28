from app.services.decomposer import ClaimDecomposer


def test_plain_claim_returns_one_atomic_claim():
    atomic_claims = ClaimDecomposer().decompose("Redis 是关系型数据库。")

    assert len(atomic_claims) == 1
    assert atomic_claims[0].text == "Redis 是关系型数据库。"
    assert atomic_claims[0].focus == "claim"


def test_fastapi_causal_claim_is_split_into_two_atomic_claims():
    atomic_claims = ClaimDecomposer().decompose(
        "FastAPI 比 Django 快是因为 FastAPI 是多线程。"
    )

    assert [atomic_claim.focus for atomic_claim in atomic_claims] == [
        "performance_comparison",
        "causal_reason",
    ]
    assert atomic_claims[0].text == "FastAPI 在某些场景下可能比 Django 快。"
    assert atomic_claims[1].text == "FastAPI 快的原因是它是多线程。"


def test_decomposition_does_not_add_private_context():
    atomic_claims = ClaimDecomposer().decompose(
        "FastAPI 比 Django 快是因为 FastAPI 是多线程。"
    )
    combined = " ".join(atomic_claim.text for atomic_claim in atomic_claims)

    assert "speaker" not in combined.lower()
    assert "conversation" not in combined.lower()
    assert "私人内容" not in combined
