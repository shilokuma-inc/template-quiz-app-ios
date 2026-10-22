//
//  ScreenshotDemo.swift
//  QuizTemplateApp
//
//  App Store 用スクリーンショットの撮影モード。
//  Tools/capture_screenshots.sh が次の起動引数でアプリを起動し、目的の画面をデモデータで開かせる。
//
//    -screenshot-demo -screenshot-scene <Scene の rawValue> -AppleLanguages (<言語>) -AppleLocale <ロケール>
//
//  画面を足すときは、Scene に case を足し、QuizTemplateApp.swift の rootView で開く画面を返し、
//  AppStore/screenshots.json の scenes に同じ rawValue を足す（突き合わせは Tools/app_store_config.py が行う）。
//  デモデータは実データと混ざらないよう、撮影モードのときだけメモリ上やインメモリのストアに用意する。
//

import Foundation
import QuizCore

enum ScreenshotDemo {
    /// 撮る画面。rawValue が AppStore/screenshots.json の scene と対応する
    enum Scene: String {
        /// ホーム
        case home
        /// 練習の出題中（3 問目）
        case quiz
        /// 結果（10 問中 9 問正解・自己ベスト更新）
        case result
    }

    /// 撮影モードで起動しているか
    static let isEnabled = ProcessInfo.processInfo.arguments.contains("-screenshot-demo")

    /// 撮影モードで開く画面。撮影モードでないときと、知らない値を渡されたときは nil
    static let scene: Scene? = {
        guard isEnabled else {
            return nil
        }
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-screenshot-scene"), arguments.indices.contains(index + 1) else {
            return nil
        }
        return Scene(rawValue: arguments[index + 1])
    }()

    /// 撮る出題の設定
    static let setting = PlaySetting(mode: .practice, difficulty: .normal, questionCount: 10)

    /// 撮り直しても同じ出題になるよう固定するシード
    static let seed: UInt64 = 20_261_022

    /// 1 問あたりの解答にかかったことにする秒数
    static let elapsedSeconds: TimeInterval = 2.0

    /// 練習の 3 問目。2 問を正解した状態
    @MainActor
    static func quizSession() -> QuizSession<Question> {
        session(answering: 2, missing: [])
    }

    /// 練習を解き終えた結果。5 問目だけ間違えた状態
    @MainActor
    static func resultSession() -> QuizSession<Question> {
        session(answering: setting.questionCount, missing: [4], isFinished: true)
    }

    /// 決まった出題を `answeredCount` 問まで解いた 1 プレイ。`missing` の問題（0 始まり）は間違える
    @MainActor
    static func session(answering answeredCount: Int, missing: Set<Int>, isFinished: Bool = false) -> QuizSession<Question> {
        let session = QuestionDeck.makeSession(setting: setting, seed: seed)
        let choices = session.questions.prefix(answeredCount).enumerated().map { index, question in
            let choice = missing.contains(index)
                ? question.choices.first { $0 != question.correctChoice } ?? question.correctChoice
                : question.correctChoice
            return (choice, elapsedSeconds: elapsedSeconds)
        }
        session.restore(answeredChoices: choices, isFinished: isFinished)
        return session
    }
}
