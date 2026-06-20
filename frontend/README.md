# DengKiller

SwiftUI iPhone MVP for the PRD in `PRD.md`.

## What is implemented

- SwiftUI app shell for “对话事实护盾”.
- Real recording entry point backed by Apple Speech and `AVAudioEngine`.
- Sentence finalization from ASR partial/final transcripts.
- Mock transcription flow for tests and simulator-safe development.
- Claim worthiness scoring with PRD thresholds.
- Mock verification client for no-backend development.
- Review screen for medium-confidence and uncertain claims.
- Unit tests for core workflow, sentence finalization, mock labels, failure/retry, and privacy boundary.
- UI tests for recording, transcript, claim, review, and non-blocking ASR failure paths.

## Generate the Xcode project

```sh
tools/xcodegen/xcodegen/bin/xcodegen generate
```

If the local XcodeGen binary is unavailable, install XcodeGen or download a release into `tools/xcodegen` first.

## Run tests

Core logic can be tested without an iOS simulator:

```sh
swift test
```

Full app and UI tests require Xcode project generation and an available iPhone simulator:

```sh
xcodebuild test -project DengKiller.xcodeproj -scheme DengKillerApp -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO
```
