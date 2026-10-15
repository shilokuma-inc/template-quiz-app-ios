import QuizCore
import SwiftUI

/// 結果画面
struct QuizResultView: View {
    let model: QuizAppModel
    let result: QuizResult
    /// 結果の元になった出題条件（「もう一度」で同じ条件から出題し直す）
    let request: QuizSessionRequest
    /// 「もう一度」「間違えた問題だけ」で次のセッションを始める
    let onRestart: (QuizSession) -> Void
    let onClose: () -> Void
    @Environment(\.quizTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                score
                actions
                review
            }
            .padding()
        }
        .background(theme.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AdBannerSlot(provider: model.configuration.ads.provider, placement: .resultBanner)
        }
        .task {
            await model.presentInterstitialIfNeeded()
        }
    }

    // MARK: - Sections

    private var score: some View {
        VStack(spacing: 16) {
            Text(message)
                .font(.title2.bold())
                .padding(.top, 24)
            ZStack {
                ProgressRing(value: result.accuracy, lineWidth: 14, color: theme.primary)
                VStack(spacing: 4) {
                    Text("\(result.correctCount) / \(result.totalCount)")
                        .font(.largeTitle.bold().monospacedDigit())
                        .accessibilityIdentifier("resultScore")
                    Text("正答率 \(result.accuracy.percentText)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 180, height: 180)
            .accessibilityElement(children: .combine)
        }
    }

    private var message: String {
        switch result.accuracy {
        case 1: "パーフェクト！"
        case 0.8...: "すばらしい！"
        case 0.5...: "いい調子！"
        default: "復習してみよう"
        }
    }

    private var actions: some View {
        let incorrectIDs = result.incorrectQuestionIDs
        return VStack(spacing: 12) {
            if !incorrectIDs.isEmpty {
                Button {
                    restart(model.makeSession(scope: .questions(incorrectIDs)))
                } label: {
                    Label("間違えた問題に再挑戦（\(incorrectIDs.count) 問）", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.quizPrimary)
                .accessibilityIdentifier("retryIncorrectButton")
            }

            let retryButton = Button {
                restart(model.makeSession(repeating: request))
            } label: {
                Label("もう一度挑戦する", systemImage: "play.fill")
            }
            .accessibilityIdentifier("retryButton")
            // 間違えた問題があればそちらを主ボタンにする
            if incorrectIDs.isEmpty {
                retryButton.buttonStyle(.quizPrimary)
            } else {
                retryButton.buttonStyle(.quizSecondary)
            }

            Button("ホームに戻る", action: onClose)
                .buttonStyle(.quizSecondary)
                .accessibilityIdentifier("backHomeButton")
        }
    }

    private func restart(_ session: QuizSession?) {
        if let session {
            onRestart(session)
        }
    }

    private var review: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ふりかえり")
                .font(.headline)
            ForEach(result.entries) { entry in
                ReviewRow(entry: entry)
            }
        }
    }
}

private struct ReviewRow: View {
    let entry: QuizResult.Entry
    @State private var isExpanded = false
    @Environment(\.quizTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: entry.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(entry.isCorrect ? theme.correct : theme.incorrect)
                        .accessibilityLabel(entry.isCorrect ? "正解" : "不正解")
                    Text(entry.question.text)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.down")
                        .font(.footnote.bold())
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    if let answer = entry.question.answer {
                        Text("正解: \(answer)")
                            .font(.subheadline.bold())
                            .foregroundStyle(theme.correct)
                    }
                    if !entry.isCorrect {
                        Text("あなたの回答: \(entry.selectedChoice ?? "未回答")")
                            .font(.subheadline)
                            .foregroundStyle(theme.incorrect)
                    }
                    if let explanation = entry.question.explanation {
                        Text(explanation)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.leading, 36)
                .transition(.opacity)
            }
        }
        .quizCard()
    }
}
