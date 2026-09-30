import Foundation

/// 1 アプリ分の問題データ。アプリに同梱する `quiz.json` の中身そのもの。
///
/// 問題の作成（外部委託）は CSV で行い、`quiz-tool import` でこの形式の JSON に変換する。
/// 形式を変える場合は `schemaVersion` を上げ、古い形式の読み込みを残すこと。
public struct QuizPack: Codable, Sendable, Equatable {
    /// このコードが読み書きできる形式のバージョン
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    /// 表示順に並んだカテゴリ
    public var categories: [QuizCategory]
    /// 問題（カテゴリ内の表示順は配列の順）
    public var questions: [QuizQuestion]

    public init(
        schemaVersion: Int = QuizPack.currentSchemaVersion,
        categories: [QuizCategory],
        questions: [QuizQuestion]
    ) {
        self.schemaVersion = schemaVersion
        self.categories = categories
        self.questions = questions
    }

    public func category(id: QuizCategory.ID) -> QuizCategory? {
        categories.first { $0.id == id }
    }

    public func questions(in categoryID: QuizCategory.ID) -> [QuizQuestion] {
        questions.filter { $0.categoryID == categoryID }
    }
}

public struct QuizCategory: Codable, Sendable, Hashable, Identifiable {
    /// 成績の保存キーにも使うため、公開後は変更しない
    public var id: String
    public var name: String
    public var summary: String?
    /// SF Symbols の名前。未指定なら UI 側の既定アイコンを使う
    public var iconSystemName: String?

    public init(id: String, name: String, summary: String? = nil, iconSystemName: String? = nil) {
        self.id = id
        self.name = name
        self.summary = summary
        self.iconSystemName = iconSystemName
    }
}

public struct QuizQuestion: Codable, Sendable, Hashable, Identifiable {
    /// 成績の保存キーにも使うため、公開後は変更しない（問題文を直しても id は据え置く）
    public var id: String
    public var categoryID: QuizCategory.ID
    public var text: String
    /// 選択肢（2〜6 個）。表示時にシャッフルされる
    public var choices: [String]
    /// 正解の選択肢の位置（0 始まり。CSV では 1 始まりで書く）
    public var answerIndex: Int
    public var explanation: String?
    /// アプリの Asset Catalog に登録した画像名
    public var imageName: String?
    /// true のとき選択肢をシャッフルしない（「上記すべて」のような順序に意味がある問題向け）
    public var keepsChoiceOrder: Bool

    public init(
        id: String,
        categoryID: QuizCategory.ID,
        text: String,
        choices: [String],
        answerIndex: Int,
        explanation: String? = nil,
        imageName: String? = nil,
        keepsChoiceOrder: Bool = false
    ) {
        self.id = id
        self.categoryID = categoryID
        self.text = text
        self.choices = choices
        self.answerIndex = answerIndex
        self.explanation = explanation
        self.imageName = imageName
        self.keepsChoiceOrder = keepsChoiceOrder
    }

    public var answer: String? {
        choices.indices.contains(answerIndex) ? choices[answerIndex] : nil
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case categoryID = "categoryId"
        case text
        case choices
        case answerIndex
        case explanation
        case imageName
        case keepsChoiceOrder
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        categoryID = try container.decode(String.self, forKey: .categoryID)
        text = try container.decode(String.self, forKey: .text)
        choices = try container.decode([String].self, forKey: .choices)
        answerIndex = try container.decode(Int.self, forKey: .answerIndex)
        explanation = try container.decodeIfPresent(String.self, forKey: .explanation)
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
        keepsChoiceOrder = try container.decodeIfPresent(Bool.self, forKey: .keepsChoiceOrder) ?? false
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(categoryID, forKey: .categoryID)
        try container.encode(text, forKey: .text)
        try container.encode(choices, forKey: .choices)
        try container.encode(answerIndex, forKey: .answerIndex)
        try container.encodeIfPresent(explanation, forKey: .explanation)
        try container.encodeIfPresent(imageName, forKey: .imageName)
        // 既定値の false は省略して JSON の差分を小さくする
        if keepsChoiceOrder {
            try container.encode(keepsChoiceOrder, forKey: .keepsChoiceOrder)
        }
    }
}

// MARK: - JSON

extension QuizPack {
    public enum DecodingError: LocalizedError, Equatable {
        case unsupportedSchemaVersion(Int)

        public var errorDescription: String? {
            switch self {
            case let .unsupportedSchemaVersion(version):
                "未対応の問題データ形式です（schemaVersion: \(version)、対応: \(QuizPack.currentSchemaVersion)）"
            }
        }
    }

    public static func decode(from data: Data) throws -> QuizPack {
        let pack = try JSONDecoder().decode(QuizPack.self, from: data)
        guard pack.schemaVersion == currentSchemaVersion else {
            throw DecodingError.unsupportedSchemaVersion(pack.schemaVersion)
        }
        return pack
    }

    /// キー順を固定した整形済み JSON。生成物を Git で差分レビューできるようにする
    public func encodedJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(self)
        data.append(contentsOf: Array("\n".utf8))
        return data
    }
}
