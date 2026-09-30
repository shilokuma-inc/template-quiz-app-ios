import Foundation

/// ユーザーが設定画面で変更できる項目
public struct QuizSettings: Codable, Sendable, Equatable {
    /// 1 回の出題数。nil ならすべての問題
    public var questionCount: Int?
    public var shufflesChoices: Bool
    public var hapticsEnabled: Bool

    public init(questionCount: Int? = 10, shufflesChoices: Bool = true, hapticsEnabled: Bool = true) {
        self.questionCount = questionCount
        self.shufflesChoices = shufflesChoices
        self.hapticsEnabled = hapticsEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case questionCount
        case shufflesChoices
        case hapticsEnabled
    }

    /// 項目を追加しても、保存済みの古い設定を読み込めるよう欠けた項目は既定値で補う
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = QuizSettings()
        questionCount = try container.decodeIfPresent(Int.self, forKey: .questionCount)
        shufflesChoices = try container.decodeIfPresent(Bool.self, forKey: .shufflesChoices) ?? defaults.shufflesChoices
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? defaults.hapticsEnabled
    }
}
