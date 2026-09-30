// 問題 CSV を quiz.json に変換・検証する CLI。
//
//   swift run --package-path Packages/QuizKit quiz-tool import <content-dir> <output.json>
//   swift run --package-path Packages/QuizKit quiz-tool check <content-dir> <output.json>
//   swift run --package-path Packages/QuizKit quiz-tool validate <quiz.json>
//
// 通常はリポジトリルートの scripts/import-quiz.sh から呼ぶ。

import Foundation
import QuizCore

let usage = """
    usage:
      quiz-tool import <content-dir> <output.json>   CSV を検証して JSON を書き出す
      quiz-tool check <content-dir> <output.json>    CSV から生成した JSON と既存の JSON が一致するか確認する（CI 用）
      quiz-tool validate <quiz.json>                 JSON を検証する

    <content-dir> には categories.csv と questions.csv を置く（UTF-8 / Shift_JIS）。
    """

struct ToolError: LocalizedError {
    var errorDescription: String?

    init(_ message: String) {
        errorDescription = message
    }
}

func readText(at url: URL) throws -> String {
    let data: Data
    do {
        data = try Data(contentsOf: url)
    } catch {
        throw ToolError("\(url.path) を読み込めません")
    }
    // Excel（日本語環境）で保存した CSV は Shift_JIS になるため、UTF-8 で読めなければ Shift_JIS として読む
    if let text = String(data: data, encoding: .utf8) {
        return text
    }
    if let text = String(data: data, encoding: .shiftJIS) {
        printWarning("\(url.lastPathComponent) を Shift_JIS として読み込みました。可能なら UTF-8 で保存してください")
        return text
    }
    throw ToolError("\(url.path) の文字コードを判別できません（UTF-8 で保存してください）")
}

func makePack(contentDirectory: URL) throws -> QuizPack {
    let categories = contentDirectory.appending(path: "categories.csv")
    let questions = contentDirectory.appending(path: "questions.csv")
    let pack = try QuizCSVImporter.makePack(
        categoriesCSV: readText(at: categories),
        questionsCSV: readText(at: questions),
        categoriesFileName: categories.relativePathForDisplay,
        questionsFileName: questions.relativePathForDisplay
    )
    try report(QuizPackValidator.validate(pack))
    return pack
}

/// 警告は表示だけ、エラーがあれば失敗させる
func report(_ issues: [QuizValidationIssue]) throws {
    issues.warnings.forEach { printWarning($0.description) }
    let errors = issues.errors
    guard errors.isEmpty else {
        throw ToolError((["問題データにエラーが \(errors.count) 件あります"] + errors.map(\.description)).joined(separator: "\n"))
    }
}

func printWarning(_ message: String) {
    FileHandle.standardError.write(Data("warning: \(message)\n".utf8))
}

func summary(of pack: QuizPack) -> String {
    let lines = pack.categories.map { category in
        "  - \(category.name)（\(category.id)）: \(pack.questions(in: category.id).count) 問"
    }
    return (["カテゴリ \(pack.categories.count) 件 / 問題 \(pack.questions.count) 問"] + lines).joined(separator: "\n")
}

extension URL {
    var relativePathForDisplay: String {
        let current = FileManager.default.currentDirectoryPath + "/"
        return path.hasPrefix(current) ? String(path.dropFirst(current.count)) : path
    }
}

func run(_ arguments: [String]) throws {
    switch (arguments.first, arguments.count) {
    case ("import", 3):
        let pack = try makePack(contentDirectory: URL(filePath: arguments[1]))
        let output = URL(filePath: arguments[2])
        try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
        try pack.encodedJSON().write(to: output, options: .atomic)
        print("\(output.relativePathForDisplay) を書き出しました")
        print(summary(of: pack))

    case ("check", 3):
        let expected = try makePack(contentDirectory: URL(filePath: arguments[1])).encodedJSON()
        let output = URL(filePath: arguments[2])
        guard (try? Data(contentsOf: output)) == expected else {
            throw ToolError("\(output.relativePathForDisplay) が CSV の内容と一致しません。scripts/import-quiz.sh を実行して再生成してください")
        }
        print("\(output.relativePathForDisplay) は CSV の内容と一致しています")

    case ("validate", 2):
        let url = URL(filePath: arguments[1])
        let pack = try QuizPack.decode(from: Data(contentsOf: url))
        try report(QuizPackValidator.validate(pack))
        print(summary(of: pack))

    default:
        throw ToolError(usage)
    }
}

do {
    try run(Array(CommandLine.arguments.dropFirst()))
} catch {
    FileHandle.standardError.write(Data("error: \(error.localizedDescription)\n".utf8))
    exit(1)
}
