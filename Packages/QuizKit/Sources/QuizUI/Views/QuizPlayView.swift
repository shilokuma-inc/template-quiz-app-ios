import QuizCore
import SwiftUI

/// 出題画面。最後の問題を解き終えたら同じ画面のまま結果を表示する
struct QuizPlayView: View {
    let model: QuizAppModel
    @State private var session: QuizSession
    @State private var isConfirmingQuit = false
    @Environment(\.quizTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    init(model: QuizAppModel, session: QuizSession) {
        self.model = model
        _session = State(initialValue: session)
    }

    var body: some View {
        Group {
            if session.isFinished {
                QuizResultView(model: model, result: session.result, request: session.request) { next in
                    session = next
                } onClose: {
                    dismiss()
                }
                .transition(.opacity)
            } else if let item = session.currentItem {
                question(item)
                    // 問題が変わるたびに View を作り直してスクロール位置などをリセットする
                    .id(item.id)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session.currentIndex)
        .background(theme.background)
        .confirmationDialog("クイズを中断しますか？", isPresented: $isConfirmingQuit, titleVisibility: .visible) {
            Button("中断する", role: .destructive) {
                model.record(session.result, completed: false)
                dismiss()
            }
            Button("続ける", role: .cancel) {}
        } message: {
            Text("ここまでに回答した問題は記録されます")
        }
        .sensoryFeedback(trigger: session.currentSelection) { _, selection in
            guard model.settings.hapticsEnabled, let selection, let item = session.currentItem else {
                return nil
            }
            return selection == item.correctDisplayIndex ? .success : .error
        }
    }

    private func question(_ item: QuizSession.Item) -> some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    questionBody(item)
                    choices(item)
                    if let selection = session.currentSelection {
                        feedback(item, selection: selection)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding()
                .animation(.easeOut(duration: 0.2), value: session.currentSelection)
            }
            if session.currentSelection != nil {
                nextButton
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Parts

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    isConfirmingQuit = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("中断")
                .accessibilityIdentifier("quitButton")

                Spacer()

                Text("\(session.currentIndex + 1) / \(session.items.count)")
                    .font(.headline.monospacedDigit())
                    .accessibilityIdentifier("questionCounter")

                Spacer()

                // タイトルを中央に置くための余白（中断ボタンと同じ幅）
                Color.clear.frame(width: 44, height: 44)
            }
            // 回答した時点で 1 問分進める
            let answeredCount = session.currentIndex + (session.currentSelection == nil ? 0 : 1)
            ProgressView(value: Double(answeredCount), total: Double(session.items.count))
                .tint(theme.primary)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func questionBody(_ item: QuizSession.Item) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let category = model.pack?.category(id: item.question.categoryID) {
                Text(category.name)
                    .font(.caption.bold())
                    .foregroundStyle(theme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(theme.primary.opacity(0.12), in: .capsule)
            }
            Text(item.question.text)
                .font(.title3.bold())
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("questionText")
            if let imageName = item.question.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 220)
                    .clipShape(.rect(cornerRadius: theme.cornerRadius))
            }
        }
    }

    private func choices(_ item: QuizSession.Item) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(item.displayedChoices.enumerated()), id: \.offset) { index, choice in
                ChoiceButton(
                    text: choice,
                    state: choiceState(index: index, item: item)
                ) {
                    session.answer(displayIndex: index)
                }
                // disabled だと正解・不正解の色まで薄くなるため、タップだけを止める
                .allowsHitTesting(session.currentSelection == nil)
                .accessibilityIdentifier("choice_\(index)")
            }
        }
    }

    private func choiceState(index: Int, item: QuizSession.Item) -> ChoiceButton.State {
        guard let selection = session.currentSelection else {
            return .normal
        }
        if index == item.correctDisplayIndex {
            return .correct
        }
        return index == selection ? .incorrect : .dimmed
    }

    private func feedback(_ item: QuizSession.Item, selection: Int) -> some View {
        let isCorrect = selection == item.correctDisplayIndex
        return VStack(alignment: .leading, spacing: 8) {
            Label(isCorrect ? "正解！" : "不正解…", systemImage: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title3.bold())
                .foregroundStyle(isCorrect ? theme.correct : theme.incorrect)
                .accessibilityIdentifier("answerFeedback")
            if !isCorrect, let answer = item.question.answer {
                Text("正解は「\(answer)」")
                    .font(.subheadline.bold())
            }
            if let explanation = item.question.explanation {
                Text(explanation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .quizCard()
    }

    private var nextButton: some View {
        Button {
            session.advance()
            if session.isFinished {
                model.record(session.result, completed: true)
            }
        } label: {
            Text(session.isLastItem ? "結果を見る" : "次の問題へ")
        }
        .buttonStyle(.quizPrimary)
        .accessibilityIdentifier("nextButton")
    }
}

/// 選択肢のボタン。回答後は正解・不正解で色を変える
private struct ChoiceButton: View {
    enum State {
        case normal
        case correct
        case incorrect
        case dimmed
    }

    let text: String
    let state: State
    let action: () -> Void
    @Environment(\.quizTheme) private var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(text)
                    .font(.body.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let icon {
                    Image(systemName: icon)
                        .font(.title3)
                }
            }
            .foregroundStyle(foreground)
            .padding()
            .frame(minHeight: 56)
            .background(background, in: .rect(cornerRadius: theme.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .strokeBorder(border, lineWidth: 2)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .opacity(state == .dimmed ? 0.5 : 1)
        .accessibilityValue(accessibilityValue)
    }

    private var icon: String? {
        switch state {
        case .correct: "checkmark.circle.fill"
        case .incorrect: "xmark.circle.fill"
        case .normal, .dimmed: nil
        }
    }

    private var foreground: Color {
        switch state {
        case .correct: theme.correct
        case .incorrect: theme.incorrect
        case .normal, .dimmed: .primary
        }
    }

    private var background: Color {
        switch state {
        case .correct: theme.correct.opacity(0.12)
        case .incorrect: theme.incorrect.opacity(0.12)
        case .normal, .dimmed: theme.surface
        }
    }

    private var border: Color {
        switch state {
        case .correct: theme.correct
        case .incorrect: theme.incorrect
        case .normal, .dimmed: .clear
        }
    }

    private var accessibilityValue: String {
        switch state {
        case .correct: "正解"
        case .incorrect: "不正解"
        case .normal, .dimmed: ""
        }
    }
}

#Preview {
    let model = QuizAppModel.preview
    QuizPlayView(model: model, session: QuizSession(pack: QuizPack.preview, request: .init(scope: .all))!)
        .environment(\.quizTheme, model.configuration.theme)
}
