//
//  QuizContentTests.swift
//  QuizTemplateAppTests
//

import Foundation
import QuizCore
@testable import QuizTemplateApp
import Testing

/// 同梱したデータセットと、AppConfig の出題の作り方を確かめる。データセットを差し替えたら件数などを合わせる
@MainActor
struct QuizContentTests {
    private let items = QuizContent.items

    @Test("データセットを読めて、id と問題が重複しない")
    func contentIsValid() {
        #expect(items.count == 47)
        #expect(Set(items.map(\.id)).count == items.count)
        #expect(Set(items.map { $0.name.value(for: "ja") }).count == items.count)
    }

    @Test("AppStore/languages.json の言語（ja / en）の値がそろっている")
    func contentHasAllLanguages() {
        for item in items {
            for language in ["ja", "en"] {
                #expect(item.name.values[language]?.isEmpty == false, "\(item.id) の name に \(language) が無い")
                #expect(item.answer.values[language]?.isEmpty == false, "\(item.id) の answer に \(language) が無い")
            }
        }
    }

    @Test("どの難易度でも、選択肢の数がそろい正解を含む", arguments: Difficulty.allCases)
    func generatorMakesValidQuestions(difficulty: Difficulty) {
        var generator = AppConfig.makeGenerator(items: items, difficulty: difficulty)
        var random = SeededRandomNumberGenerator(seed: 1)
        for question in generator.makeQuestions(count: 50, using: &random) {
            #expect(question.choices.count == AppConfig.choiceCount)
            #expect(Set(question.choices).count == AppConfig.choiceCount)
            #expect(question.choices.contains(question.correctChoice))
            #expect(question.scoreFactor == difficulty.scoreFactor)
        }
    }

    @Test("むずかしいは level 2 の行だけを出す")
    func hardUsesLevelTwoOnly() {
        var generator = AppConfig.makeGenerator(items: items, difficulty: .hard)
        var random = SeededRandomNumberGenerator(seed: 2)
        let hardPrompts = Set(items.filter { $0.level >= 2 }.map(\.name.localized))
        #expect(generator.makeQuestions(count: 30, using: &random).allSatisfy { hardPrompts.contains($0.prompt) })
    }

    @Test("練習は決めた問題数で終わり、タイムアタックは補充し続ける")
    func sessionsFollowMode() {
        let practice = QuestionDeck.makeSession(setting: PlaySetting(mode: .practice, difficulty: .easy, questionCount: 5))
        #expect(practice.questions.count == 5)
        #expect(practice.rules.timeLimitSeconds == nil)

        let timeAttack = QuestionDeck.makeSession(setting: PlaySetting(mode: .timeAttack(seconds: 30), difficulty: .easy, questionCount: 5))
        // タイムアタックは問題数の設定を使わず、まとまった数を作って残りが少なくなったら補充する
        #expect(timeAttack.questions.count == QuestionDeck.batchSize)
        #expect(timeAttack.rules.timeLimitSeconds == 30)
    }

    @Test("選べる問題数なら同じ問題を出さない", arguments: Difficulty.allCases)
    func noDuplicatePromptsInPractice(difficulty: Difficulty) {
        let counts = PlaySetting.questionCounts(for: difficulty)
        #expect(!counts.isEmpty)
        for count in counts {
            #expect(count <= AppConfig.questionPoolSize(for: difficulty))
            let session = QuestionDeck.makeSession(setting: PlaySetting(mode: .practice, difficulty: difficulty, questionCount: count))
            #expect(session.questions.count == count)
            #expect(Set(session.questions.map(\.prompt)).count == count)
        }
    }

    @Test("候補より多い問題数は外し、難易度を変えたら選べる問題数にそろえる")
    func questionCountsFollowPoolSize() {
        // むずかしいの候補は 17 件なので、20 問は選べない
        #expect(PlaySetting.questionCounts(for: .hard) == [5, 10])
        #expect(PlaySetting.questionCounts(for: .normal) == AppConfig.questionCounts)
        #expect(PlaySetting.questionCounts(poolSize: 3) == [3])

        let hard = PlaySetting(mode: .practice, difficulty: .hard, questionCount: 20).adjustingQuestionCount()
        #expect(hard.questionCount == 10)
        let normal = PlaySetting(mode: .practice, difficulty: .normal, questionCount: 20).adjustingQuestionCount()
        #expect(normal.questionCount == 20)
    }

    @Test("ランキングの枠はモード・難易度・問題数で分かれる")
    func leaderboardKeysAreDistinct() {
        let keys = Set(AppConfig.modes.flatMap { mode in
            Difficulty.allCases.flatMap { difficulty in
                AppConfig.questionCounts.map { PlaySetting(mode: mode, difficulty: difficulty, questionCount: $0).leaderboardKey }
            }
        })
        // タイムアタックは問題数を使わない
        let practiceCount = Difficulty.allCases.count * AppConfig.questionCounts.count
        let timeAttackCount = (AppConfig.modes.count - 1) * Difficulty.allCases.count
        #expect(keys.count == practiceCount + timeAttackCount)
        let style = RankingStyle.localAndGameCenter(leaderboardIDPrefix: "jp.example.quiz.")
        #expect(style.gameCenterLeaderboardID(for: .default) == "jp.example.quiz.practice_10_normal")
        #expect(RankingStyle.local.gameCenterLeaderboardID(for: .default) == nil)
    }

    @Test("撮影モードの進行状態")
    func screenshotDemo() {
        let quiz = ScreenshotDemo.quizSession()
        #expect(quiz.currentIndex == 2)
        #expect(!quiz.isFinished)

        let result = ScreenshotDemo.resultSession()
        #expect(result.isFinished)
        #expect(result.score.correctCount == ScreenshotDemo.setting.questionCount - 1)
        // 撮り直しても同じ出題になる
        #expect(ScreenshotDemo.quizSession().questions == quiz.questions)
    }
}
