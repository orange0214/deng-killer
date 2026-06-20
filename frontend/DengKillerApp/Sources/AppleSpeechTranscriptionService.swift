import AVFoundation
import DengKillerCore
import Foundation
import Speech

@MainActor
final class AppleSpeechTranscriptionService: AudioTranscriptionService {
    private let audioEngine = AVAudioEngine()
    private let recognizer: SFSpeechRecognizer?
    private let localeIdentifier: String
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var continuation: AsyncStream<TranscriptionEvent>.Continuation?
    private var finalizer = SentenceFinalizer()
    private var isAudioTapInstalled = false

    init(locale: Locale = Locale(identifier: "zh_CN")) {
        localeIdentifier = locale.identifier
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
        if isAudioTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isAudioTapInstalled = false
        }
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        continuation?.finish()
        continuation = nil
        finalizer.reset()
    }

    private func requestPermissionsAndStart() async {
        let speechAuthorized = await Self.requestSpeechAuthorization()
        guard speechAuthorized else {
            yield(.permissionDenied("需要开启语音识别权限，才能把对话转写为文字。"))
            finish()
            return
        }

        let microphoneAuthorized = await Self.requestMicrophoneAuthorization()
        guard microphoneAuthorized else {
            yield(.permissionDenied("需要开启麦克风权限，才能记录对话。"))
            finish()
            return
        }

        do {
            try startAudioRecognition()
        } catch {
            yield(.failed(recordingStartMessage(for: error)))
            stopTranscribing()
        }
    }

    private func startAudioRecognition() throws {
        guard let recognizer else {
            yield(.failed("当前系统不支持 \(localeIdentifier) 语音识别。请换用真机或调整识别语言后重试。"))
            finish()
            return
        }

        guard recognizer.isAvailable else {
            yield(.failed(speechUnavailableMessage()))
            finish()
            return
        }

        recognitionTask?.cancel()
        recognitionTask = nil
        finalizer.reset()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        try configureAudioSession()

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            throw RecordingStartError.inputUnavailable
        }

        if isAudioTapInstalled {
            inputNode.removeTap(onBus: 0)
            isAudioTapInstalled = false
        }
        Self.installAudioTap(on: inputNode, format: recordingFormat, request: request)
        isAudioTapInstalled = true

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = Self.startRecognitionTask(recognizer: recognizer, request: request, service: self)
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        guard session.isInputAvailable else {
            throw RecordingStartError.inputUnavailable
        }
    }

    private nonisolated static func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private nonisolated static func requestMicrophoneAuthorization() async -> Bool {
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

    private func recordingStartMessage(for error: Error) -> String {
        if let recordingError = error as? RecordingStartError {
            return recordingError.message
        }

        let nsError = error as NSError
        if nsError.domain == NSOSStatusErrorDomain {
            return "无法开始录音。麦克风可能正被其他软件占用，或模拟器没有可用音频输入。请关闭占用麦克风的程序后重试。"
        }

        return "录音或语音识别启动失败，请确认麦克风没有被其他软件占用后重试。"
    }

    private func speechUnavailableMessage() -> String {
        #if targetEnvironment(simulator)
        return "Apple Speech 当前对 \(localeIdentifier) 不可用。模拟器经常无法使用中文流式语音识别；请确认网络和语音识别权限，或优先用真机测试。"
        #else
        return "Apple Speech 当前对 \(localeIdentifier) 暂不可用。请确认网络可用、语音识别权限已开启，稍后重试。"
        #endif
    }

    private func handleRecognitionUpdate(transcript: String?, isFinal: Bool, didFail: Bool) {
        if let transcript {
            for event in finalizer.ingest(transcript, isFinal: isFinal) {
                yield(event)
            }

            if isFinal {
                stopTranscribing()
            }
        }

        if didFail {
            yield(.failed("语音识别中断，请重新开始记录。"))
            stopTranscribing()
        }
    }

    private nonisolated static func installAudioTap(
        on inputNode: AVAudioNode,
        format: AVAudioFormat,
        request: SFSpeechAudioBufferRecognitionRequest
    ) {
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { buffer, _ in
            request.append(buffer)
        }
    }

    private nonisolated static func startRecognitionTask(
        recognizer: SFSpeechRecognizer,
        request: SFSpeechAudioBufferRecognitionRequest,
        service: AppleSpeechTranscriptionService
    ) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: request) { [weak service] result, error in
            let transcript = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let didFail = error != nil

            Task { @MainActor [weak service] in
                service?.handleRecognitionUpdate(transcript: transcript, isFinal: isFinal, didFail: didFail)
            }
        }
    }
}

private enum RecordingStartError: Error {
    case inputUnavailable

    var message: String {
        switch self {
        case .inputUnavailable:
            return "没有检测到可用麦克风输入。请确认模拟器允许使用 Mac 麦克风，且麦克风没有被其他软件占用。"
        }
    }
}
