@testable import QuizCore
import Testing

struct CSVParserTests {
    @Test
    func parsesSimpleRows() throws {
        let records = try CSVParser.parse("a,b,c\n1,2,3\n")
        #expect(records.map(\.fields) == [["a", "b", "c"], ["1", "2", "3"]])
        #expect(records.map(\.line) == [1, 2])
    }

    @Test
    func parsesQuotedFieldsWithCommaNewlineAndEscapedQuote() throws {
        let records = try CSVParser.parse("id,text\r\n1,\"a,b\r\n\"\"c\"\"\"\r\n2,d")
        #expect(records.map(\.fields) == [["id", "text"], ["1", "a,b\r\n\"c\""], ["2", "d"]])
        // セル内の改行があっても、次のレコードの行番号は実際の行に合わせる
        #expect(records.map(\.line) == [1, 2, 4])
    }

    @Test
    func removesBOMAndKeepsEmptyFields() throws {
        let records = try CSVParser.parse("\u{FEFF}a,,c\n,,\n")
        #expect(records.map(\.fields) == [["a", "", "c"], ["", "", ""]])
    }

    @Test
    func throwsOnUnclosedQuote() {
        #expect(throws: CSVParser.ParseError.self) {
            try CSVParser.parse("a\n\"unclosed\n")
        }
    }

    @Test
    func throwsOnQuoteInsideUnquotedField() {
        #expect(throws: CSVParser.ParseError(line: 2, reason: "クォートされていないセルの途中に \" があります")) {
            try CSVParser.parse("a\nab\"c\n")
        }
    }
}
