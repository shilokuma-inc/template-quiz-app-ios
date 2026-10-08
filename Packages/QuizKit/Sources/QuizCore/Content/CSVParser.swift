import Foundation

/// RFC 4180 形式の CSV を行・列に分解する。
///
/// Excel / Google スプレッドシートの書き出しを想定し、以下に対応する。
/// - ダブルクォートで囲んだセル（セル内のカンマ・改行・`""` によるクォートのエスケープ）
/// - 改行コード CRLF / LF / CR
/// - 先頭の BOM
public enum CSVParser {
    public struct ParseError: LocalizedError, Equatable {
        /// エラーが見つかった行（1 始まり）
        public var line: Int
        public var reason: String

        public var errorDescription: String? {
            "CSV の \(line) 行目: \(reason)"
        }
    }

    /// 1 レコード分のセルと、そのレコードが始まる行番号（1 始まり）
    public struct Record: Equatable, Sendable {
        public var line: Int
        public var fields: [String]
    }

    public static func parse(_ text: String) throws -> [Record] {
        var scalars = Array(text.unicodeScalars)
        if scalars.first == "\u{FEFF}" {
            scalars.removeFirst()
        }
        var state = State(scalars: scalars)
        return try state.parse()
    }

    /// 1 文字ずつ読み進める状態
    private struct State {
        let scalars: [Unicode.Scalar]
        var index = 0
        var records: [Record] = []
        var fields: [String] = []
        var field = ""
        var inQuotes = false
        var fieldWasQuoted = false
        var line = 1
        var recordStartLine = 1

        init(scalars: [Unicode.Scalar]) {
            self.scalars = scalars
        }

        mutating func parse() throws -> [Record] {
            while index < scalars.count {
                if inQuotes {
                    readQuoted(scalars[index])
                } else {
                    try readUnquoted(scalars[index])
                }
                index += 1
            }
            if inQuotes {
                throw ParseError(line: recordStartLine, reason: "クォートが閉じられていません")
            }
            // 末尾が改行で終わっていない最終行
            if !field.isEmpty || fieldWasQuoted || !fields.isEmpty {
                endRecord()
            }
            return records
        }

        private var next: Unicode.Scalar? {
            index + 1 < scalars.count ? scalars[index + 1] : nil
        }

        private mutating func readQuoted(_ scalar: Unicode.Scalar) {
            if scalar == "\"" {
                if next == "\"" {
                    // "" はクォート文字そのもの
                    field.unicodeScalars.append("\"")
                    index += 1
                } else {
                    inQuotes = false
                }
                return
            }
            // セル内の改行も行番号に数える（CRLF は 1 行）
            if scalar == "\n" || (scalar == "\r" && next != "\n") {
                line += 1
            }
            field.unicodeScalars.append(scalar)
        }

        private mutating func readUnquoted(_ scalar: Unicode.Scalar) throws {
            switch scalar {
            case "\"":
                guard field.isEmpty, !fieldWasQuoted else {
                    throw ParseError(line: line, reason: "クォートされていないセルの途中に \" があります")
                }
                inQuotes = true
                fieldWasQuoted = true

            case ",":
                endField()

            case "\r", "\n":
                if scalar == "\r", next == "\n" {
                    index += 1
                }
                endRecord()
                line += 1
                recordStartLine = line

            default:
                if fieldWasQuoted {
                    throw ParseError(line: line, reason: "閉じクォートの後に文字があります")
                }
                field.unicodeScalars.append(scalar)
            }
        }

        private mutating func endField() {
            fields.append(field)
            field = ""
            fieldWasQuoted = false
        }

        private mutating func endRecord() {
            endField()
            records.append(Record(line: recordStartLine, fields: fields))
            fields = []
        }
    }
}
