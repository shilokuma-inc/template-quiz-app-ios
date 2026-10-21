//
//  RankingView.swift
//  QuizTemplateApp
//

import QuizCore
import QuizGameCenter
import QuizUI
import SwiftUI

/// ランキング。端末の中の記録（モード × 難易度ごとの上位 10 件）と、Game Center を使うなら全員のランキングへの入口
struct RankingView: View {
    @Environment(\.quizTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gameCenter: GameCenterLeaderboard
    @State private var setting: PlaySetting
    @State private var isGameCenterPresented = false

    init(initialSetting: PlaySetting) {
        _setting = State(initialValue: initialSetting)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing) {
                    if AppConfig.modes.count > 1 {
                        QuizOptionPicker(AppConfig.modes, selection: $setting.mode) { Text($0.title) }
                    }
                    if AppConfig.difficulties.count > 1 {
                        QuizOptionPicker(AppConfig.difficulties, selection: $setting.difficulty) { Text($0.title) }
                    }
                    if setting.mode == .practice, AppConfig.questionCounts.count > 1 {
                        QuizOptionPicker(AppConfig.questionCounts, selection: $setting.questionCount) { Text("\($0)") }
                    }
                    LocalLeaderboardView(records: LocalLeaderboard().records(forKey: setting.leaderboardKey))

                    if let leaderboardID = AppConfig.ranking.gameCenterLeaderboardID(for: setting), gameCenter.isAuthenticated {
                        Button("Game Center") {
                            isGameCenterPresented = true
                        }
                        .buttonStyle(.bordered)
                        .tint(theme.accent)
                        .sheet(isPresented: $isGameCenterPresented) {
                            GameCenterLeaderboardView(leaderboardID: leaderboardID)
                        }
                    }
                }
                .padding(theme.spacing)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(Text("Ranking"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
