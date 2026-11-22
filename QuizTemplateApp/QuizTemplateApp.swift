//
//  QuizTemplateApp.swift
//  QuizTemplateApp
//
//  Created by 村石 拓海 on 2024/05/12.
//

import QuizGameCenter
import QuizUI
import SwiftUI

@main
struct QuizTemplateApp: App {
    @StateObject private var gameCenter = GameCenterLeaderboard()

    var body: some Scene {
        WindowGroup {
            rootView
                .quizTheme(AppConfig.theme)
                .environmentObject(gameCenter)
                .task {
                    // Game Center を使うときだけサインインを始める。撮影モードでは出さない
                    if AppConfig.ranking.gameCenterLeaderboardID(for: .default) != nil, !ScreenshotDemo.isEnabled {
                        gameCenter.authenticate()
                    }
                }
        }
    }

    /// 撮影モード（ScreenshotDemo）のときは、撮る画面を開く
    @ViewBuilder private var rootView: some View {
        switch ScreenshotDemo.scene {
        case .home, nil:
            HomeView()
        case .quiz:
            NavigationStack {
                PlayView(setting: ScreenshotDemo.setting, session: ScreenshotDemo.quizSession())
            }
        case .result:
            NavigationStack {
                PlayView(setting: ScreenshotDemo.setting, session: ScreenshotDemo.resultSession(), isNewRecord: true)
            }
        }
    }
}
