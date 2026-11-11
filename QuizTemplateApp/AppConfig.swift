//
//  AppConfig.swift
//  QuizTemplateApp
//
//  新しいクイズアプリを作るときに書き換えるのは、このファイルと Content/（データセット）と AppStore/（掲載情報）だけ。
//  出題・進行・スコア・ランキングは QuizKit（shilokuma-inc/quiz-kit）が持つ。
//

import QuizCore
import QuizUI
import SwiftUI

/// 出題の型。問題として見せる値（`prompt`）と選択肢（`choices`）がどちらも文字列の択一問題
typealias Question = ChoiceQuestion<String, String>

enum AppConfig {
    // MARK: - 見た目

    /// 色・書体・角丸・間隔。標準画面（QuizUI）はすべてここから読む
    static let theme = QuizTheme(
        background: Color(red: 0.95, green: 0.97, blue: 1.0),
        accent: Color(red: 0.16, green: 0.42, blue: 0.86),
        correct: Color(red: 0.18, green: 0.66, blue: 0.38),
        incorrect: Color(red: 0.90, green: 0.29, blue: 0.29)
    )

    /// ホームに出すアプリ名とひとこと
    static let title: LocalizedStringResource = "Capital Quiz"
    static let subtitle: LocalizedStringResource = "Name the capitals of all 47 prefectures"

    /// 問題の見せ方。画像を見せるクイズ（国旗など）は `Image(question.prompt)` にする
    @ViewBuilder
    static func promptView(_ question: Question) -> some View {
        Text("What is the capital of \(question.prompt)?")
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.5)
    }

    // MARK: - 出題

    /// 選択肢の数（2 択なら 2）
    static let choiceCount = 4
    /// 練習で選べる問題数
    static let questionCounts = [5, 10, 20]
    static let defaultQuestionCount = 10
    /// ホームで選べるモード。1 つだけなら選択を出さない
    static let modes: [PlayMode] = [.practice, .timeAttack(seconds: 30)]
    /// ホームで選べる難易度。1 つだけなら選択を出さない
    static let difficulties: [Difficulty] = Difficulty.allCases

    /// データセット（`Content/` の JSON のファイル名）
    static let contentFileName = "quiz-items"

    /// 難易度ごとの出題の作り方。データセットのどの列を問題・答えにし、どの行を出し、誤答をどう選ぶかを決める
    static func makeGenerator(items: [QuizItem], difficulty: Difficulty) -> ChoiceQuestionGenerator<QuizItem, String, String> {
        // むずかしいは、県名と違う名前の県庁所在地（level 2）だけを出す。誤答には全件を使う
        let candidates = difficulty == .hard ? items.filter { $0.level >= 2 } : items
        // ふつう・むずかしいは同じ地方から誤答を選んで紛らわしくする
        let distractorGroup: (@Sendable (QuizItem) -> AnyHashable)?
        if difficulty == .easy {
            distractorGroup = nil
        } else {
            distractorGroup = { @Sendable (item: QuizItem) -> AnyHashable in AnyHashable(item.group) }
        }
        let factor = difficulty.scoreFactor
        return ChoiceQuestionGenerator(
            items: candidates,
            distractorPool: items,
            choiceCount: choiceCount,
            prompt: { (item: QuizItem) -> String in item.name.localized },
            answer: { (item: QuizItem) -> String in item.answer.localized },
            distractorGroup: distractorGroup,
            scoreFactor: { (_: QuizItem) -> Double in factor }
        )
    }

    /// 難易度ごとの候補（出しうる問題）の数。練習で選べる問題数はこれを超えない
    static func questionPoolSize(for difficulty: Difficulty) -> Int {
        makeGenerator(items: QuizContent.items, difficulty: difficulty).items.count
    }

    // MARK: - ランキング

    /// `.none`（出さない）/ `.local`（端末の中で自分と競う）/ `.localAndGameCenter`（Game Center でも競う）
    ///
    /// Game Center を使うときは、Signing & Capabilities で Game Center を有効にし、
    /// App Store Connect で `<leaderboardIDPrefix><PlaySetting.leaderboardKey>` の ID のリーダーボードを作る。
    static let ranking: RankingStyle = .local
}
