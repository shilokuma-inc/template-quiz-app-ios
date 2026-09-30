//
//  QuizTemplateApp.swift
//  QuizTemplateApp
//
//  Created by 村石 拓海 on 2024/05/12.
//

import QuizUI
import SwiftUI

@main
struct QuizTemplateApp: App {
    var body: some Scene {
        WindowGroup {
            // 画面・出題ロジック・成績・設定は QuizKit が持つ。
            // アプリごとの違いは AppConfiguration.swift と Content/（問題 CSV）、Asset Catalog に閉じ込める
            QuizRootView(configuration: .app)
        }
    }
}
