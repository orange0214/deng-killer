# Deng Killer

对话中的事实护盾：记录对话、抽取可核验事实主张，并以低打扰方式提示可能错误的陈述。

当前仓库是一个 monorepo，计划同时承载 iPhone 前端和后端核验服务。

## Structure

```text
.
├── PRD.md
├── frontend/
└── backend/        # planned
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

The backend is planned but not implemented yet. Per the PRD, it should eventually provide a FastAPI service for claim verification while avoiding storage of full audio, full transcripts, or ordinary user claims by default.

