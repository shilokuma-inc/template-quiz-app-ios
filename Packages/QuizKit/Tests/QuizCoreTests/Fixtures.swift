@testable import QuizCore

enum Fixtures {
    static let pack = QuizPack(
        categories: [
            QuizCategory(id: "fruit", name: "くだもの"),
            QuizCategory(id: "animal", name: "どうぶつ")
        ],
        questions: [
            QuizQuestion(id: "q1", categoryID: "fruit", text: "赤い果物は？", choices: ["りんご", "バナナ", "メロン"], answerIndex: 0),
            QuizQuestion(id: "q2", categoryID: "fruit", text: "黄色い果物は？", choices: ["りんご", "バナナ", "メロン"], answerIndex: 1),
            QuizQuestion(id: "q3", categoryID: "animal", text: "鳴き声がワンなのは？", choices: ["ねこ", "いぬ"], answerIndex: 1),
            QuizQuestion(
                id: "q4",
                categoryID: "animal",
                text: "当てはまるものは？",
                choices: ["ねこ", "いぬ", "上記すべて"],
                answerIndex: 2,
                keepsChoiceOrder: true
            )
        ]
    )
}

/// 再現性のある乱数（テストでシャッフル結果を固定する）
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        // SplitMix64
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}
