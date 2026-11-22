//
//  PlayView.swift
//  QuizTemplateApp
//

import QuizCore
import QuizGameCenter
import QuizUI
import SwiftUI

/// 出題と結果。進行は QuizKit の `QuizSession`、画面は QuizUI の標準画面を使う
struct PlayView: View {
    let setting: PlaySetting
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gameCenter: GameCenterLeaderboard
    @State private var session: QuizSession<Question>
    @State private var isNewRecord = false
    @State private var bestScore: Int?
    /// 撮影モードの画面か。記録を残さない
    private let isDemo: Bool

    init(setting: PlaySetting) {
        self.setting = setting
        isDemo = false
        _session = State(initialValue: QuestionDeck.makeSession(setting: setting))
    }

    /// 撮影モードやプレビュー用。決まった出題と途中までの進行から始める
    init(setting: PlaySetting, session: QuizSession<Question>, isNewRecord: Bool = false) {
        self.setting = setting
        isDemo = true
        _session = State(initialValue: session)
        _isNewRecord = State(initialValue: isNewRecord)
    }

    var body: some View {
        Group {
            if session.isFinished {
                QuizResultView(session: session, isNewRecord: isNewRecord, bestScore: bestScore) {
                    VStack(spacing: 12) {
                        Button {
                            restart()
                        } label: {
                            Text("Play Again")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        Button("Home") {
                            dismiss()
                        }
                        .controlSize(.large)
                    }
                    .tint(AppConfig.theme.accent)
                }
            } else {
                QuizPlayView(session: session, layout: .automatic(choiceCount: AppConfig.choiceCount)) { question in
                    AppConfig.promptView(question)
                }
            }
        }
        .sensoryFeedback(trigger: session.answers.count) { _, _ in
            session.answers.last.map { $0.isCorrect ? .success : .error }
        }
        .navigationTitle(Text(setting.mode.title))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: session.isFinished) { _, isFinished in
            if isFinished {
                recordScore()
            }
        }
    }

    /// 解き終えた・時間切れなら記録する。途中でやめたら記録しない
    private func recordScore() {
        guard !isDemo, session.finishReason != .quit, AppConfig.ranking.showsRanking else { return }
        let score = session.score.totalScore
        let leaderboard = LocalLeaderboard()
        let previousBest = leaderboard.bestScore(forKey: setting.leaderboardKey)
        isNewRecord = leaderboard.record(score: score, forKey: setting.leaderboardKey)
        bestScore = max(previousBest ?? 0, score)
        if let leaderboardID = AppConfig.ranking.gameCenterLeaderboardID(for: setting) {
            Task { await gameCenter.submit(score: score, leaderboardID: leaderboardID) }
        }
    }

    private func restart() {
        isNewRecord = false
        bestScore = nil
        session = QuestionDeck.makeSession(setting: setting)
    }
}

#Preview {
    NavigationStack {
        PlayView(setting: .default)
    }
    .environmentObject(GameCenterLeaderboard())
    .quizTheme(AppConfig.theme)
}
