import Foundation

public struct SentenceFinalizer {
    private var finalizedText = ""
    private let speaker: String
    private let startDate: Date
    private var sequence = 0

    public init(speaker: String = "A", startDate: Date = Date()) {
        self.speaker = speaker
        self.startDate = startDate
    }

    public mutating func ingest(_ transcript: String, isFinal: Bool, now: Date = Date()) -> [TranscriptionEvent] {
        let normalizedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTranscript.isEmpty else { return [] }

        let pendingText = pendingText(from: normalizedTranscript)
        guard !pendingText.isEmpty else { return [] }

        var events: [TranscriptionEvent] = []
        let finalizedPieces = finalizedSentences(from: pendingText, forceFinalize: isFinal)

        for piece in finalizedPieces.sentences {
            sequence += 1
            finalizedText += piece
            events.append(
                .final(
                    TranscriptSentence(
                        speaker: speaker,
                        startTime: timestamp(forSequenceOffset: sequence - 1, now: now),
                        endTime: timestamp(forSequenceOffset: sequence, now: now),
                        text: piece,
                        isFinal: true
                    )
                )
            )
        }

        if !finalizedPieces.remainder.isEmpty {
            events.append(.partial(finalizedPieces.remainder))
        }

        return events
    }

    public mutating func reset() {
        finalizedText = ""
        sequence = 0
    }

    private func pendingText(from transcript: String) -> String {
        if transcript.hasPrefix(finalizedText) {
            return String(transcript.dropFirst(finalizedText.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func finalizedSentences(from text: String, forceFinalize: Bool) -> (sentences: [String], remainder: String) {
        var sentences: [String] = []
        var current = ""

        for character in text {
            current.append(character)
            if Self.terminalPunctuation.contains(character) {
                let sentence = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !sentence.isEmpty {
                    sentences.append(sentence)
                }
                current = ""
            }
        }

        let remainder = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if forceFinalize, !remainder.isEmpty {
            sentences.append(remainder)
            return (sentences, "")
        }

        return (sentences, remainder)
    }

    private func timestamp(forSequenceOffset offset: Int, now: Date) -> String {
        let elapsedSeconds = max(0, Int(now.timeIntervalSince(startDate))) + offset
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private static let terminalPunctuation: Set<Character> = ["。", "！", "？", ".", "!", "?"]
}
