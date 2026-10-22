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

    /// 出しうる問題の数
    var poolSize: Int {
        generator.items.count
    }
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
            // 候補より多く作ると同じ問題が重なるので、候補の数で止める（ホームでもそれを超える問題数は選ばせない）
            let count = min(setting.questionCount, deck.poolSize)
            return QuizSession(questions: deck.next(count: count), rules: setting.mode.rules)
        case .timeAttack:
            return QuizSession(
                questions: deck.next(count: batchSize),
                rules: setting.mode.rules,
                refill: { deck.next(count: batchSize) }
            )
        }
    }
}
