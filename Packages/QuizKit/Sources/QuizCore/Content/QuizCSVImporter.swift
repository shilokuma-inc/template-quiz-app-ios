import Foundation

/// 外部委託で作成した問題 CSV（categories.csv / questions.csv）を `QuizPack` に変換する。
///
/// 列は 1 行目のヘッダー名で判定するため、列の順番は自由で、未知の列（委託先のメモ欄など）は無視する。
/// 列の仕様は docs/quiz-content.md を参照。
public enum QuizCSVImporter {
    public static let maxChoiceCount = QuizPackValidator.choiceCountRange.upperBound

    public enum CategoryColumn {
        public static let id = "id"
        public static let name = "name"
        public static let summary = "summary"
        public static let icon = "icon"
        public static let required = [id, name]
    }

    public enum QuestionColumn {
        public static let id = "id"
        public static let categoryID = "category_id"
        public static let question = "question"
        public static let answer = "answer"
        public static let explanation = "explanation"
        public static let image = "image"
        public static let fixedOrder = "fixed_order"
        public static func choice(_ number: Int) -> String { "choice_\(number)" }
        public static let required = [id, categoryID, question, choice(1), choice(2), answer]
    }

    /// 取り込み時のエラー 1 件
    public struct Issue: Sendable, Hashable, CustomStringConvertible {
        public var file: String
        /// CSV の行番号（1 始まり、ヘッダー行を含む）。ファイル全体の問題なら nil
        public var line: Int?
        public var message: String

        public var description: String {
            if let line {
                "\(file):\(line): \(message)"
            } else {
                "\(file): \(message)"
            }
        }
    }

    public struct ImportError: LocalizedError, Sendable {
        public var issues: [Issue]

        public var errorDescription: String? {
            (["問題 CSV の取り込みに失敗しました（\(issues.count) 件）"] + issues.map(\.description))
                .joined(separator: "\n")
        }
    }

    /// - Parameters:
    ///   - categoriesCSV: categories.csv の内容
    ///   - questionsCSV: questions.csv の内容
    ///   - categoriesFileName / questionsFileName: エラーメッセージに出すファイル名
    public static func makePack(
        categoriesCSV: String,
        questionsCSV: String,
        categoriesFileName: String = "categories.csv",
        questionsFileName: String = "questions.csv"
    ) throws -> QuizPack {
        var issues: [Issue] = []
        let categories = parseCategories(categoriesCSV, file: categoriesFileName, issues: &issues)
        let questions = parseQuestions(questionsCSV, file: questionsFileName, issues: &issues)
        guard issues.isEmpty else {
            throw ImportError(issues: issues)
        }
        return QuizPack(categories: categories, questions: questions)
    }

    // MARK: - categories.csv

    private static func parseCategories(_ csv: String, file: String, issues: inout [Issue]) -> [QuizCategory] {
        guard let table = Table(csv: csv, file: file, requiredColumns: CategoryColumn.required, issues: &issues) else {
            return []
        }
        return table.rows.map { row in
            QuizCategory(
                id: row[CategoryColumn.id],
                name: row[CategoryColumn.name],
                summary: row[CategoryColumn.summary].nilIfEmpty,
                iconSystemName: row[CategoryColumn.icon].nilIfEmpty
            )
        }
    }

    // MARK: - questions.csv

    private static func parseQuestions(_ csv: String, file: String, issues: inout [Issue]) -> [QuizQuestion] {
        guard let table = Table(csv: csv, file: file, requiredColumns: QuestionColumn.required, issues: &issues) else {
            return []
        }
        return table.rows.compactMap { row in
            let choices = (1...maxChoiceCount)
                .map { row[QuestionColumn.choice($0)] }
                .filter { !$0.isEmpty }

            let answerText = row[QuestionColumn.answer]
            // 全角数字（「２」など）で入力されることがあるため半角に直して読む
            let halfwidthAnswer = answerText.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? answerText
            guard let answerNumber = Int(halfwidthAnswer) else {
                let message = "answer は正解の選択肢の番号（1〜\(maxChoiceCount)）で指定してください: \"\(answerText)\""
                issues.append(Issue(file: file, line: row.line, message: message))
                return nil
            }

            return QuizQuestion(
                id: row[QuestionColumn.id],
                categoryID: row[QuestionColumn.categoryID],
                text: row[QuestionColumn.question],
                choices: choices,
                answerIndex: answerNumber - 1,
                explanation: row[QuestionColumn.explanation].nilIfEmpty,
                imageName: row[QuestionColumn.image].nilIfEmpty,
                keepsChoiceOrder: parseFlag(row[QuestionColumn.fixedOrder])
            )
        }
    }

    /// 委託先がスプレッドシートで入力しやすいよう、真偽値は複数の表記を受け付ける
    private static func parseFlag(_ value: String) -> Bool {
        ["1", "true", "yes", "○", "〇", "y"].contains(value.lowercased())
    }
}

// MARK: - Table

/// ヘッダー行で列名を引けるようにした CSV
private struct Table {
    struct Row {
        var line: Int
        var values: [String: String]

        /// 列が存在しない・空のときは空文字列。前後の空白は取り除く
        subscript(column: String) -> String {
            values[column] ?? ""
        }
    }

    var rows: [Row]

    init?(csv: String, file: String, requiredColumns: [String], issues: inout [QuizCSVImporter.Issue]) {
        let records: [CSVParser.Record]
        do {
            records = try CSVParser.parse(csv)
        } catch let error as CSVParser.ParseError {
            issues.append(.init(file: file, line: error.line, message: error.reason))
            return nil
        } catch {
            issues.append(.init(file: file, line: nil, message: error.localizedDescription))
            return nil
        }

        guard let header = records.first else {
            issues.append(.init(file: file, line: nil, message: "ファイルが空です"))
            return nil
        }
        let columns = header.fields.map { $0.trimmed.lowercased() }
        let missing = requiredColumns.filter { !columns.contains($0) }
        guard missing.isEmpty else {
            issues.append(.init(file: file, line: header.line, message: "必須の列がありません: \(missing.joined(separator: ", "))"))
            return nil
        }

        var rows: [Row] = []
        for record in records.dropFirst() {
            // スプレッドシートの書き出しで末尾に付きがちな空行は無視する
            guard record.fields.contains(where: { !$0.trimmed.isEmpty }) else {
                continue
            }
            // カンマを含むセルをクォートし忘れると列がずれるため、ヘッダーより多い列はエラーにする。
            // ずれた分が空の列に収まり、はみ出した列が空になることもあるので、空かどうかに関係なく列数で判定する
            if record.fields.count > columns.count {
                issues.append(.init(
                    file: file,
                    line: record.line,
                    message: "列の数がヘッダーより多くなっています。カンマを含むセルは \"\" で囲んでください"
                ))
                continue
            }
            var values: [String: String] = [:]
            for (column, value) in zip(columns, record.fields) where !column.isEmpty {
                values[column] = value.trimmed
            }
            rows.append(Row(line: record.line, values: values))
        }
        self.rows = rows
    }
}

extension String {
    fileprivate var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
