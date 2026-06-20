import AVFoundation
import DengKillerCore
import Foundation
import Speech

@MainActor
final class AppleSpeechTranscriptionService: AudioTranscriptionService {
    private let audioEngine = AVAudioEngine()
    private let recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var continuation: AsyncStream<TranscriptionEvent>.Continuation?
    private var finalizer = SentenceFinalizer()

    init(locale: Locale = Locale(identifier: "zh_CN")) {
        recognizer = SFSpeechRecognizer(locale: locale)
    }

    func startTranscribing() -> AsyncStream<TranscriptionEvent> {
        AsyncStream { continuation in
            self.continuation = continuation
            Task { @MainActor in
                await self.requestPermissionsAndStart()
            }
        }
    }

    func stopTranscribing() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        continuation?.finish()
        continuation = nil
        finalizer.reset()
    }

    private func requestPermissionsAndStart() async {
        let speechAuthorized = await requestSpeechAuthorization()
        guard speechAuthorized else {
            yield(.permissionDenied("需要开启语音识别权限，才能把对话转写为文字。"))
            finish()
            return
        }

        let microphoneAuthorized = await requestMicrophoneAuthorization()
        guard microphoneAuthorized else {
            yield(.permissionDenied("需要开启麦克风权限，才能记录对话。"))
            finish()
            return
        }

        do {
            try startAudioRecognition()
        } catch {
            yield(.failed("录音或语音识别启动失败，请稍后重试。"))
            finish()
        }
    }

    private func startAudioRecognition() throws {
        guard let recognizer, recognizer.isAvailable else {
            yield(.failed("当前语音识别服务不可用，请稍后重试。"))
            finish()
            return
        }

        recognitionTask?.cancel()
        recognitionTask = nil
        finalizer.reset()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }

                if let result {
                    let transcript = result.bestTranscription.formattedString
                    for event in self.finalizer.ingest(transcript, isFinal: result.isFinal) {
                        self.yield(event)
                    }

                    if result.isFinal {
                        self.stopTranscribing()
                    }
                }

                if error != nil {
                    self.yield(.failed("语音识别中断，请重新开始记录。"))
                    self.stopTranscribing()
                }
            }
        }
    }

    private func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophoneAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func yield(_ event: TranscriptionEvent) {
        continuation?.yield(event)
    }

    private func finish() {
        continuation?.finish()
        continuation = nil
    }
}
