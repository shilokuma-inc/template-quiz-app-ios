//
//  HomeView.swift
//  QuizTemplateApp
//

import QuizUI
import SwiftUI

/// ホーム。モード・難易度・問題数を選んで始める
struct HomeView: View {
    @Environment(\.quizTheme) private var theme
    @State private var setting = PlaySetting.default
    @State private var path: [PlaySetting] = []
    @State private var isRankingPresented = false

    /// いまの難易度で選べる問題数
    private var questionCounts: [Int] {
        PlaySetting.questionCounts(for: setting.difficulty)
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: theme.spacing * 1.5) {
                Spacer()
                VStack(spacing: theme.spacing / 2) {
                    Text(AppConfig.title)
                        .font(theme.titleFont)
                        .foregroundStyle(theme.primaryText)
                    Text(AppConfig.subtitle)
                        .font(theme.bodyFont)
                        .foregroundStyle(theme.secondaryText)
                }
                .multilineTextAlignment(.center)
                Spacer()

                if AppConfig.modes.count > 1 {
                    section("Mode") {
                        QuizOptionPicker(AppConfig.modes, selection: $setting.mode) { Text($0.title) }
                    }
                }
                if AppConfig.difficulties.count > 1 {
                    section("Difficulty") {
                        QuizOptionPicker(AppConfig.difficulties, selection: $setting.difficulty) { Text($0.title) }
                    }
                }
                if setting.mode == .practice, questionCounts.count > 1 {
                    section("Questions") {
                        QuizOptionPicker(questionCounts, selection: $setting.questionCount) { Text("\($0)") }
                    }
                }

                Button {
                    path.append(setting)
                } label: {
                    Text("Start")
                        .font(theme.questionFont)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.spacing)
                        .background(Capsule().fill(theme.accent))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("start")

                if AppConfig.ranking.showsRanking {
                    Button("Ranking") {
                        isRankingPresented = true
                    }
                    .font(theme.choiceFont)
                    .tint(theme.accent)
                }
            }
            .padding(theme.spacing)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.background.ignoresSafeArea())
            .animation(.snappy, value: setting.mode)
            .onChange(of: setting.difficulty) {
                setting = setting.adjustingQuestionCount()
            }
            .navigationDestination(for: PlaySetting.self) { setting in
                PlayView(setting: setting)
            }
            .sheet(isPresented: $isRankingPresented) {
                RankingView(initialSetting: setting)
            }
        }
    }

    private func section(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing / 2) {
            Text(title)
                .font(theme.bodyFont.weight(.semibold))
                .foregroundStyle(theme.secondaryText)
            content()
        }
    }
}

#Preview {
    HomeView()
        .quizTheme(AppConfig.theme)
}
