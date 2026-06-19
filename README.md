# Deng Killer

对话中的事实护盾：记录对话、抽取可核验事实主张，并以低打扰方式提示可能错误的陈述。

当前仓库是一个 monorepo，包含 iPhone 前端和后端核验服务 scaffold。

## Structure

```text
.
├── PRD.md
├── frontend/       # SwiftUI iPhone MVP
└── backend/        # FastAPI claim verification scaffold
```

## Frontend

The iPhone MVP lives in `frontend/`.

Open the Xcode project:

```sh
cd frontend
open DengKiller.xcodeproj
```

Regenerate the Xcode project after editing `frontend/project.yml`:

```sh
cd frontend
tools/xcodegen/xcodegen/bin/xcodegen generate
```

Run core tests:

```sh
cd frontend
swift test
```

Run full iOS tests with an available simulator:

```sh
cd frontend
xcodebuild test -project DengKiller.xcodeproj -scheme DengKillerApp -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO
```

## Backend

The backend scaffold lives in `backend/`. It provides a small FastAPI service
for single-claim verification and keeps the PRD privacy boundary explicit:

- `GET /health`
- `POST /v1/claims/verify`
- Pydantic schemas aligned with the Swift `VerificationRequest` and
  `VerificationResult` models.
- Rule-based mock verification for MVP examples.
- Privacy guard that rejects full audio, full transcripts, full conversations,
  messages, and speaker history.

Set up the backend with `uv`:

```sh
cd backend
uv sync --extra dev
```

Run the API:

```sh
cd backend
uv run uvicorn app.main:app --reload
```

Run backend tests:

```sh
cd backend
uv run pytest
```

The backend does not yet include real search, LLM integration, persistent
storage, accounts, or full conversation upload. See `backend/README.md` for the
backend architecture and privacy rules.

## TODO

Frontend work remaining from `PRD.md`:

- Add real audio capture with `AVAudioEngine`, including permission handling,
  audio segmentation, and basic volume/activity handling.
- Add ASR with Apple Speech or an on-device Whisper-style model.
- Keep the current rule that ASR partial transcripts do not trigger claim
  processing; only finalized sentences should enter the claim pipeline.
- Replace the demo/mock conversation flow with real recording, transcript, and
  finalized sentence handling.
- Keep full audio, full transcripts, session review, and verification results
  local to the phone by default.
- Add local deletion controls for single sessions and an optional auto-delete
  period.
- Improve low-interruption notifications: lightweight real-time state for high
  confidence/high importance claims, plus richer after-conversation review.
- Add UI support for evidence summaries, uncertainty explanations, and sources
  once the backend returns them.

Backend work remaining from `PRD.md`:

- Replace the rule-based mock verifier with real claim extraction,
  checkworthiness scoring, and initial classification.
- Add claim decomposition for complex claims before evidence lookup.
- Add hybrid retrieval: search first for open-world or time-sensitive claims,
  with lightweight RAG for curated stable sources.
- Add evidence judgement that compares retrieved evidence with each atomic
  claim instead of relying on model intuition alone.
- Add verdict generation that preserves `verdict`, `confidence`, `issue`,
  `correction`, `evidence_summary`, and future source citations.
- Add streaming verification progress, such as `received`, `classifying`,
  `retrieving`, `judging_evidence`, and `completed`.
- Add feedback and opt-in error-example endpoints without uploading full
  conversations by default.
- Add privacy-safe logging that stores only non-content metadata such as
  request id, latency, status code, and model version.
- Add optional storage for curated public sources, public evidence cache,
  verification metadata, and user-authorized high-confidence error examples.
- Add high-risk domain safeguards for political, medical, legal, and investment
  claims: evidence and limitations only, no final decision advice.

## Privacy Boundary

Deng Killer must default to protecting the user's full conversation:

- Do not upload full audio by default.
- Do not upload full transcripts by default.
- Do not upload speaker history or full conversation context by default.
- Backend verification should receive only one selected claim plus minimal
  necessary context.
- Logs and analytics must not contain private transcript or audio content.
