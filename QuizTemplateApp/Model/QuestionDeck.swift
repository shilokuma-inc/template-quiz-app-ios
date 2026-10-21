//
//  QuestionDeck.swift
//  QuizTemplateApp
//

import QuizCore

/// 1 プレイ分の出題を作る
///
/// 同じ問題を続けて出さないよう、タイムアタックの補充でも同じ生成器を使い続ける。
final class QuestionDeck {
    /// タイムアタックで一度に作る問題数
    static let batchSize = 10

    private var generator: ChoiceQuestionGenerator<QuizItem, String, String>
    private var random: any RandomNumberGenerator

    init(setting: PlaySetting, items: [QuizItem] = QuizContent.items, seed: UInt64? = nil) {
        generator = AppConfig.makeGenerator(items: items, difficulty: setting.difficulty)
        random = seed.map { SeededRandomNumberGenerator(seed: $0) } ?? SystemRandomNumberGenerator()
    }

    func next(count: Int) -> [Question] {
        generator.makeQuestions(count: count, using: &random)
    }

    /// 設定に合った 1 プレイ。タイムアタックは残りが少なくなったら補充する
    @MainActor
    static func makeSession(setting: PlaySetting, seed: UInt64? = nil) -> QuizSession<Question> {
        let deck = QuestionDeck(setting: setting, seed: seed)
        switch setting.mode {
        case .practice:
            return QuizSession(questions: deck.next(count: setting.questionCount), rules: setting.mode.rules)
        case .timeAttack:
            return QuizSession(
                questions: deck.next(count: batchSize),
                rules: setting.mode.rules,
                refill: { deck.next(count: batchSize) }
            )
        }
    }
}
