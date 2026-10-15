//
//  AppConfiguration.swift
//  QuizTemplateApp
//
//  アプリごとに差し替える設定。新しいクイズアプリを作るときは主にこのファイルを書き換える。
//  （問題は Content/ の CSV、色・画像は Assets.xcassets、アプリ名・Bundle ID は Configs/Project.xcconfig）
//

import Foundation
import QuizCore
import QuizUI
import SwiftUI

extension QuizAppConfiguration {
    static var app: QuizAppConfiguration {
        QuizAppConfiguration(
            // ホーム画面のタイトル。省略すると Configs/Project.xcconfig の APP_DISPLAY_NAME を使う
            // appName: "日本地理クイズ",
            tagline: "都道府県・山や川・世界遺産の知識をチェック",
            theme: QuizTheme(
                primary: .themePrimary,
                background: .themeBackground,
                surface: .themeSurface,
                fontDesign: .rounded,
                cornerRadius: 16,
                // Assets.xcassets に画像を追加して名前を指定すると、ホーム上部の画像を差し替えられる
                heroImageName: nil,
                heroSystemImage: "map.fill"
            ),
            // Content/ の CSV から scripts/import-quiz.sh で生成した Resources/quiz.json を読み込む
            contentProvider: BundleQuizContentProvider(),
            questionCountOptions: [5, 10, 20],
            defaultQuestionCount: 10,
            links: QuizAppConfiguration.Links(
                // TODO: リリース前に実際の URL に差し替える（プライバシーポリシーは App Store の審査で必須）
                privacyPolicy: URL(string: "https://example.com/privacy"),
                termsOfUse: nil,
                support: URL(string: "https://example.com/contact")
            ),
            ads: adConfiguration
        )
    }

    /// 広告 SDK を組み込むまでは、Debug ビルドでだけ広告枠の位置をダミー表示する
    private static var adConfiguration: AdConfiguration {
        #if DEBUG
        AdConfiguration(provider: PlaceholderAdProvider(), interstitialInterval: 3)
        #else
        .none
        #endif
    }
}
