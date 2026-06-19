# Deng Killer Backend Architecture

This folder contains the first backend scaffold for the planned verification
service. The current implementation is intentionally small: it exposes the
planned FastAPI API shape, uses a rule-based mock verifier, and keeps the
privacy boundary testable before any real search or model integration is added.

The first backend version should follow `PRD.md`: a small Python + FastAPI
service that verifies one checkworthy factual claim at a time. The service must
not become a full conversation upload, transcript storage, debate assistant, or
account system.

## Product Boundary

Deng Killer is a low-interruption fact-checking assistant. Backend output should
help the user understand which claims are worth checking, what the evidence
suggests, and how to say a more accurate version gently.

The backend must not:

- Help users attack, shame, or overpower another speaker.
- Treat initial or evidence-based labels as final advice in high-risk domains.
- Provide final medical, legal, investment, or political decision guidance.
- Store or process full private conversations by default.

## Run Locally

Install dependencies from this folder:

```sh
uv sync --extra dev
```

Run the API:

```sh
uv run uvicorn app.main:app --reload
```

Run backend tests:

```sh
uv run pytest
```

## Service API

### `GET /health`

Returns a minimal health response for deployment and client readiness checks.

Example response:

```json
{
  "status": "ok"
}
```

### `POST /v1/claims/verify`

Verifies a single claim using only the claim and minimal necessary context.

This endpoint is the backend counterpart of the current Swift
`VerificationRequest` and `VerificationResult` models in `DengKillerCore`.

Request:

```json
{
  "claim": "FastAPI 比 Django 快是因为 FastAPI 是多线程。",
  "minimal_context": "FastAPI 比 Django 快是因为 FastAPI 是多线程。",
  "language": "zh-Hans",
  "domain": "technical_fact"
}
```

Request fields:

- `claim`: The single factual claim selected for verification.
- `minimal_context`: Optional minimal context needed to interpret this claim.
  This must not contain full transcript history.
- `language`: BCP-47-style language tag used for output language preference.
- `domain`: Claim domain. Expected values should stay compatible with the
  Swift `ClaimType` enum: `technical_fact`, `business_fact`, `civic_fact`,
  `subjective`, or `unknown`.

Response:

```json
{
  "original_claim": "FastAPI 比 Django 快是因为 FastAPI 是多线程。",
  "verdict": "possibly_false",
  "confidence": 0.82,
  "issue": "该陈述将 FastAPI 的性能优势归因于多线程，原因不准确。",
  "correction": "FastAPI 在某些高并发 I/O 场景下表现较好，主要原因通常与 ASGI、Starlette 和 async/await 异步处理有关，而不是框架本身是多线程。",
  "evidence_summary": [
    "FastAPI 基于 Starlette，并支持 ASGI。",
    "FastAPI 支持 async/await 异步请求处理。",
    "多线程更多与部署服务器或运行环境有关，不是 FastAPI 的核心设计原因。"
  ]
}
```

Response fields:

- `original_claim`: Echo of the claim being verified.
- `verdict`: One of `likely_true`, `possibly_false`, `uncertain`,
  `needs_context`, or `controversial`.
- `confidence`: Evidence-backed confidence from `0.0` to `1.0`.
- `issue`: Short explanation of the likely problem, uncertainty, or limitation.
- `correction`: A gentler and more accurate wording the user can reuse.
- `evidence_summary`: Concise evidence notes. Future implementations may add
  structured citations, but the MVP response must keep this summary.

## Current Architecture

The implementation keeps modules small and testable:

- API layer: FastAPI routes, request validation, response serialization, and
  HTTP error mapping in `app/api`.
- Schemas: Pydantic models mirroring the Swift request and result contracts.
- Verification service: A temporary rule-based verifier that mirrors the Swift
  mock client for local API integration.
- Privacy guard: Rejects payloads that attempt to send full audio, full
  transcripts, conversations, messages, or speaker history.

Current layout:

```text
backend/
├── app/
│   ├── main.py
│   ├── api/
│   ├── privacy/
│   ├── schemas/
│   └── services/
├── README.md
├── pyproject.toml
└── tests/
```

Future implementation should add claim decomposition, search/retrieval,
evidence judgement, verdict generation, and privacy-safe logging as separate
modules instead of expanding route handlers.

## Verification Flow

1. Validate that the request contains exactly one claim and optional minimal
   context.
2. Reject or ignore any payload shape that attempts to upload full audio, full
   transcript history, speaker history, or a full conversation.
3. Use the temporary rule-based verifier for known MVP examples.
4. Return uncertainty explicitly for unknown or underspecified claims.
5. Return a low-interruption, evidence-preserving result.
6. Return uncertainty explicitly for `uncertain`, `needs_context`, and
   `controversial` cases.

Future versions should replace step 3 with decomposition, query generation,
search/retrieval, evidence judgement, and verdict synthesis.

## Privacy Rules

Privacy is a core product requirement, not an implementation detail.

The backend must default to:

- No full audio upload.
- No full transcript upload.
- No full conversation upload.
- No speaker history upload.
- No default storage of raw user claims.
- No default storage of ordinary claims, complete transcripts, audio, or
  private session context.
- No logs containing raw private conversation text, full claims, full context,
  audio, or transcript content.
- No analytics events that include private claim text or transcript snippets.

Allowed by default:

- A single selected claim.
- Minimal context needed to disambiguate that claim.
- Language and domain metadata.
- Redacted operational metadata such as request ID, latency, status code, and
  coarse error category.

Saving high-confidence error examples, public evidence caches, or raw claim
content must require explicit user authorization and a separate retention
policy.

## Testing Expectations

When backend code is added later, tests should cover:

- Request and response schema compatibility with the Swift core models.
- Rejection of full conversation, full transcript, or audio-like payloads.
- Redaction behavior for logs and errors.
- Verdict generation for `likely_true`, `possibly_false`, `uncertain`,
  `needs_context`, and `controversial`.
- High-risk domain behavior that returns evidence and limitations without final
  decision advice.
- Evidence summary preservation in every non-error verification response.

Current tests cover health checks, the verification response contract, and
privacy rejection for full-conversation payloads.
