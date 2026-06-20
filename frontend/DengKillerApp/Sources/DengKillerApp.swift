import DengKillerCore
import SwiftUI

@main
struct DengKillerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: ConversationViewModel(
                    verificationClient: MockVerificationClient(),
                    transcriptionService: Self.transcriptionService()
                )
            )
        }
    }

    private static func transcriptionService() -> AudioTranscriptionService {
        let arguments = ProcessInfo.processInfo.arguments

        if arguments.contains("-useMockTranscription") {
            return MockAudioTranscriptionService(
                events: [
                    .partial("FastAPI 比 Django"),
                    .final(
                        TranscriptSentence(
                            speaker: "A",
                            startTime: "00:00",
                            endTime: "00:03",
                            text: "FastAPI 比 Django 快是因为 FastAPI 是多线程。",
                            isFinal: true
                        )
                    ),
                    .final(
                        TranscriptSentence(
                            speaker: "A",
                            startTime: "00:04",
                            endTime: "00:07",
                            text: "我觉得 Python 写起来更舒服。",
                            isFinal: true
                        )
                    )
                ],
                delayNanoseconds: 1_000_000_000
            )
        }

        if arguments.contains("-useMockTranscriptionFailure") {
            return MockAudioTranscriptionService(
                events: [
                    .failed("语音识别中断，请重新开始记录。")
                ]
            )
        }

        return AppleSpeechTranscriptionService()
    }
}
