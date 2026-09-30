import Foundation

/// 問題データの検証結果の 1 件
public struct QuizValidationIssue: Sendable, Hashable, CustomStringConvertible {
    public enum Severity: String, Sendable, Hashable {
        /// アプリで正しく出題できない。取り込み・リリースを止める
        case error
        /// 出題はできるが見直した方がよい
        case warning
    }

    public var severity: Severity
    /// 問題やカテゴリの id など、どこの指摘かを示す文字列
    public var location: String
    public var message: String

    public init(severity: Severity, location: String, message: String) {
        self.severity = severity
        self.location = location
        self.message = message
    }

    public var description: String {
        "[\(severity.rawValue)] \(location): \(message)"
    }
}

/// 問題データがアプリで出題できる状態かを検証する。
/// `quiz-tool` での取り込み時と、アプリの Unit テスト（同梱データの検証）の両方で使う。
public enum QuizPackValidator {
    public static let choiceCountRange = 2...6

    public static func validate(_ pack: QuizPack) -> [QuizValidationIssue] {
        var issues: [QuizValidationIssue] = []
        issues += validateCategories(pack)
        issues += validateQuestions(pack)
        return issues
    }

    private static func validateCategories(_ pack: QuizPack) -> [QuizValidationIssue] {
        var issues: [QuizValidationIssue] = []
        if pack.categories.isEmpty {
            issues.append(.init(severity: .error, location: "categories", message: "カテゴリが 1 つもありません"))
        }
        var seen: Set<String> = []
        for category in pack.categories {
            let location = "カテゴリ \(category.id)"
            if !isValidID(category.id) {
                issues.append(.init(severity: .error, location: location, message: "id は半角英数字・ハイフン・アンダースコアで指定してください"))
            }
            if !seen.insert(category.id).inserted {
                issues.append(.init(severity: .error, location: location, message: "id が重複しています"))
            }
            if category.name.trimmed.isEmpty {
                issues.append(.init(severity: .error, location: location, message: "カテゴリ名が空です"))
            }
            if pack.questions.allSatisfy({ $0.categoryID != category.id }) {
                issues.append(.init(severity: .warning, location: location, message: "問題が 1 問もありません"))
            }
        }
        return issues
    }

    private static func validateQuestions(_ pack: QuizPack) -> [QuizValidationIssue] {
        var issues: [QuizValidationIssue] = []
        if pack.questions.isEmpty {
            issues.append(.init(severity: .error, location: "questions", message: "問題が 1 問もありません"))
        }
        let categoryIDs = Set(pack.categories.map(\.id))
        var seen: Set<String> = []
        for question in pack.questions {
            let location = "問題 \(question.id)"
            func error(_ message: String) {
                issues.append(.init(severity: .error, location: location, message: message))
            }

            if !isValidID(question.id) {
                error("id は半角英数字・ハイフン・アンダースコアで指定してください")
            }
            if !seen.insert(question.id).inserted {
                error("id が重複しています")
            }
            if !categoryIDs.contains(question.categoryID) {
                error("存在しないカテゴリ「\(question.categoryID)」を指定しています")
            }
            if question.text.trimmed.isEmpty {
                error("問題文が空です")
            }
            if !choiceCountRange.contains(question.choices.count) {
                error("選択肢は \(choiceCountRange.lowerBound)〜\(choiceCountRange.upperBound) 個にしてください（現在 \(question.choices.count) 個）")
            }
            if question.choices.contains(where: { $0.trimmed.isEmpty }) {
                error("空の選択肢があります")
            }
            if Set(question.choices.map(\.trimmed)).count != question.choices.count {
                error("同じ内容の選択肢があります")
            }
            if !question.choices.indices.contains(question.answerIndex) {
                error("正解の番号 \(question.answerIndex + 1) に対応する選択肢がありません")
            }
        }
        return issues
    }

    /// id は成績の保存キーになるため、半角英数字・ハイフン・アンダースコアに限る
    private static func isValidID(_ id: String) -> Bool {
        !id.isEmpty && id.unicodeScalars.allSatisfy { scalar in
            scalar.isASCII && (CharacterSet.alphanumerics.contains(scalar) || scalar == "-" || scalar == "_")
        }
    }
}

extension [QuizValidationIssue] {
    public var errors: [QuizValidationIssue] {
        filter { $0.severity == .error }
    }

    public var warnings: [QuizValidationIssue] {
        filter { $0.severity == .warning }
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
