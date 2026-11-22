//
//  QuizItem.swift
//  QuizTemplateApp
//

import Foundation

/// データセットの 1 件（`Content/quiz-items.json` の `items` の 1 要素）
///
/// 列を足すときは、ここと JSON の両方に足し、`AppConfig.makeGenerator` で使う。
/// 必須でない列は Optional にすると、古い JSON もそのまま読める。
nonisolated struct QuizItem: Codable, Hashable, Sendable {
    let id: Int
    /// 問題として見せる値（都道府県名）
    let name: LocalizedText
    /// 正解（県庁所在地）
    let answer: LocalizedText
    /// 誤答を選ぶときのまとまり（地方）
    let group: String
    /// 難しさ。1 = やさしい、2 = むずかしい
    let level: Int
}

/// 言語ごとの文字列。端末の言語（アプリが対応している言語の中から選ばれたもの）の値を使い、無ければ英語、それも無ければ最初の値を使う
nonisolated struct LocalizedText: Codable, Hashable, Sendable {
    let values: [String: String]

    init(_ values: [String: String]) {
        self.values = values
    }

    init(from decoder: Decoder) throws {
        values = try decoder.singleValueContainer().decode([String: String].self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }

    /// 端末の言語の値
    var localized: String {
        value(for: Bundle.main.preferredLocalizations.first ?? "en")
    }

    func value(for language: String) -> String {
        values[language] ?? values["en"] ?? values.values.min() ?? ""
    }
}

/// `Content/` の JSON を読む
enum QuizContent {
    private struct File: Decodable {
        let items: [QuizItem]
    }

    /// アプリに同梱したデータセット。読めないのはビルドの誤りなので、起動時に気づけるよう止める
    static let items: [QuizItem] = {
        do {
            return try load(fileName: AppConfig.contentFileName, bundle: .main)
        } catch {
            fatalError("Content/\(AppConfig.contentFileName).json を読めない: \(error)")
        }
    }()

    static func load(fileName: String, bundle: Bundle) throws -> [QuizItem] {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(File.self, from: Data(contentsOf: url)).items
    }
}
