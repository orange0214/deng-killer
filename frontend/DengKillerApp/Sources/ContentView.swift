import DengKillerCore
import SwiftUI

struct ContentView: View {
    @StateObject var viewModel: ConversationViewModel

    var body: some View {
        NavigationStack {
            List {
                controlSection
                transcriptSection
                claimSection
            }
            .navigationTitle("对话事实护盾")
            .toolbar {
                NavigationLink("会后复盘") {
                    ReviewView(claims: viewModel.reviewClaims)
                }
                .accessibilityIdentifier("reviewButton")
            }
            .safeAreaInset(edge: .bottom) {
                if possibleFalseCount > 0 {
                    AlertSummaryView(
                        count: possibleFalseCount
                    )
                }
            }
        }
    }

    private var controlSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("低打扰记录对话，只把高价值事实主张送入核验。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Button(viewModel.isRecording ? "结束记录" : "开始记录对话") {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                        } else {
                            viewModel.startRecording()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("recordingButton")

                    Button("运行模拟对话") {
                        viewModel.startSimulation()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("startSimulationButton")

                    Button("重置") {
                        viewModel.reset()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("resetButton")
                }

                if let errorMessage = viewModel.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)

                        Button("重试核验") {
                            if viewModel.claims.contains(where: { $0.status == .failed }) {
                                viewModel.retryFailedClaims()
                            } else {
                                viewModel.startRecording()
                            }
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("retryButton")
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("errorBanner")
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var possibleFalseCount: Int {
        viewModel.claims.filter { $0.status == .possiblyFalse }.count
    }

    private var transcriptSection: some View {
        Section("实时转写") {
            if viewModel.sentences.isEmpty && viewModel.partialTranscript.isEmpty {
                ContentUnavailableView("还没有对话", systemImage: "waveform", description: Text("点击开始记录对话，查看句子级转写。"))
                    .accessibilityIdentifier("emptyTranscript")
            }

            if !viewModel.partialTranscript.isEmpty {
                TranscriptRow(title: "Partial", text: viewModel.partialTranscript, isPartial: true)
                    .accessibilityIdentifier("partialTranscript")
            }

            ForEach(viewModel.sentences) { sentence in
                TranscriptRow(title: "\(sentence.speaker) \(sentence.startTime)-\(sentence.endTime)", text: sentence.text, isPartial: false)
            }
        }
        .accessibilityIdentifier("transcriptSection")
    }

    private var claimSection: some View {
        Section("事实主张") {
            if viewModel.visibleClaims.isEmpty {
                Text("等待完整句子后再判断是否值得核验。")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("emptyClaims")
            }

            ForEach(viewModel.visibleClaims) { claim in
                ClaimCard(claim: claim)
            }
        }
        .accessibilityIdentifier("claimSection")
    }
}

private struct AlertSummaryView: View {
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("发现 \(count) 条可能错误")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.red)
                .accessibilityIdentifier("possibleFalseSummary")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.red.opacity(0.25))
                .frame(height: 1)
        }
        .accessibilityIdentifier("alertSummaryCard")
    }
}

private struct TranscriptRow: View {
    let title: String
    let text: String
    let isPartial: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.body)
            if isPartial {
                Text("等待句子结束后再处理")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .accessibilityIdentifier(isPartial ? "partialTranscriptRow" : "finalTranscriptRow")
    }
}

private struct ClaimCard: View {
    let claim: ClaimAssessment

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(statusTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.14), in: Capsule())
                    .foregroundStyle(statusColor)
                    .accessibilityIdentifier("claimStatus-\(claim.status.rawValue)")

                Spacer()

                Text(String(format: "%.0f%%", claim.checkworthyScore * 100))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(claim.claim)
                .font(.headline)

            Text(claim.reason)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if claim.status == .verifying {
                ProgressView("正在核验")
                    .accessibilityIdentifier("verifyingIndicator")
            }

            if let result = claim.result {
                VStack(alignment: .leading, spacing: 8) {
                    Label(result.issue, systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                    Text("更准确说法：\(result.correction)")
                        .font(.footnote)
                    ForEach(result.evidenceSummary, id: \.self) { evidence in
                        Text("• \(evidence)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier("resultCard-\(claim.status.rawValue)")
            }
        }
        .padding(.vertical, 6)
        .accessibilityIdentifier("claimCard-\(claim.status.rawValue)")
    }

    private var statusTitle: String {
        switch claim.status {
        case .ignored:
            return "已忽略"
        case .reviewLater:
            return "会后记录"
        case .verifying:
            return "正在核验"
        case .possiblyFalse:
            return "可能错误"
        case .uncertain:
            return "证据不足"
        case .needsContext:
            return "需要上下文"
        case .likelyTrue:
            return "基本正确"
        case .failed:
            return "核验失败"
        }
    }

    private var statusColor: Color {
        switch claim.status {
        case .ignored:
            return .gray
        case .reviewLater:
            return .blue
        case .verifying:
            return .orange
        case .possiblyFalse:
            return .red
        case .uncertain, .needsContext:
            return .purple
        case .likelyTrue:
            return .green
        case .failed:
            return .red
        }
    }
}
