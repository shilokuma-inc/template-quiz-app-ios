import QuizCore
import SwiftUI

/// 出題中のクイズ（fullScreenCover の item）
struct ActiveQuiz: Identifiable {
    let id = UUID()
    var session: QuizSession
}

struct HomeView: View {
    @Bindable var model: QuizAppModel
    @Environment(\.quizTheme) private var theme
    @State private var activeQuiz: ActiveQuiz?
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    if let pack = model.pack {
                        progressCard(pack: pack)
                        actions
                        categories(pack: pack)
                    }
                }
                .padding()
            }
            .background(theme.background)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AdBannerSlot(provider: model.configuration.ads.provider, placement: .homeBanner)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Label("設定", systemImage: "gearshape")
                    }
                    .accessibilityIdentifier("settingsButton")
                }
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(model: model)
        }
        .quizPlayCover(item: $activeQuiz) { quiz in
            QuizPlayView(model: model, session: quiz.session)
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 12) {
            Group {
                if let imageName = theme.heroImageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 160)
                } else {
                    Image(systemName: theme.heroSystemImage)
                        .font(.system(size: 48))
                        .foregroundStyle(theme.onPrimary)
                        .frame(width: 96, height: 96)
                        .background(theme.primary.gradient, in: .circle)
                }
            }
            .accessibilityHidden(true)

            Text(model.configuration.appName)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            if let tagline = model.configuration.tagline {
                Text(tagline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 8)
    }

    private func progressCard(pack: QuizPack) -> some View {
        let summary = model.progress.summary(for: pack.questions)
        return HStack(spacing: 20) {
            ZStack {
                ProgressRing(value: summary.learnedRate, color: theme.primary)
                Text(summary.learnedRate.percentText)
                    .font(.headline.monospacedDigit())
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 6) {
                Text("習得した問題")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(summary.learnedCount) / \(summary.totalCount) 問")
                    .font(.title3.bold().monospacedDigit())
                HStack(spacing: 12) {
                    Label(summary.accuracy?.percentText ?? "-", systemImage: "target")
                    Label("\(model.progress.completedSessionCount) 回", systemImage: "flag.checkered")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .quizCard()
        .accessibilityElement(children: .combine)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                start(.all)
            } label: {
                Label("クイズに挑戦する", systemImage: "play.fill")
            }
            .buttonStyle(.quizPrimary)
            .accessibilityIdentifier("startQuizButton")

            let incorrectIDs = model.incorrectQuestionIDs
            if !incorrectIDs.isEmpty {
                Button {
                    start(.questions(incorrectIDs))
                } label: {
                    Label("間違えた問題を復習（\(incorrectIDs.count) 問）", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.quizSecondary)
                .accessibilityIdentifier("reviewButton")
            }
        }
    }

    @ViewBuilder
    private func categories(pack: QuizPack) -> some View {
        if pack.categories.count > 1 {
            VStack(alignment: .leading, spacing: 12) {
                Text("カテゴリから選ぶ")
                    .font(.headline)
                ForEach(pack.categories) { category in
                    CategoryRow(
                        category: category,
                        summary: model.progress.summary(for: pack.questions(in: category.id))
                    ) {
                        start(.category(category.id))
                    }
                }
            }
        }
    }

    private func start(_ scope: QuizSessionRequest.Scope) {
        guard let session = model.makeSession(scope: scope) else {
            return
        }
        activeQuiz = ActiveQuiz(session: session)
    }
}

private struct CategoryRow: View {
    let category: QuizCategory
    let summary: QuizProgress.Summary
    let action: () -> Void
    @Environment(\.quizTheme) private var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: category.iconSystemName ?? "square.grid.2x2.fill")
                    .font(.title2)
                    .foregroundStyle(theme.primary)
                    .frame(width: 44, height: 44)
                    .background(theme.primary.opacity(0.12), in: .rect(cornerRadius: theme.cornerRadius / 2))

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if let summaryText = category.summary {
                        Text(summaryText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    ProgressView(value: summary.learnedRate)
                        .tint(theme.primary)
                    Text("\(summary.learnedCount) / \(summary.totalCount) 問 習得")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.leading)

                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .foregroundStyle(.tertiary)
            }
            .quizCard()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("category_\(category.id)")
    }
}

extension View {
    /// iPhone では全画面、macOS（`swift test` でのビルド用）ではシートで出題画面を出す
    @ViewBuilder
    func quizPlayCover<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, content: content)
        #else
        sheet(item: item, content: content)
        #endif
    }
}

#Preview {
    HomeView(model: .preview)
}
