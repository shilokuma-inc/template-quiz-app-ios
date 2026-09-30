import Foundation
@testable import QuizCore
import Testing

struct QuizPackTests {
    @Test
    func roundTripsThroughJSON() throws {
        let data = try Fixtures.pack.encodedJSON()
        #expect(try QuizPack.decode(from: data) == Fixtures.pack)
    }

    @Test
    func omitsDefaultKeepsChoiceOrderInJSON() throws {
        let json = try #require(String(data: Fixtures.pack.encodedJSON(), encoding: .utf8))
        // q4 だけが keepsChoiceOrder: true を持つ
        #expect(json.components(separatedBy: "keepsChoiceOrder").count == 2)
    }

    @Test
    func rejectsUnsupportedSchemaVersion() throws {
        var pack = Fixtures.pack
        pack.schemaVersion = 999
        let data = try JSONEncoder().encode(pack)
        #expect(throws: QuizPack.DecodingError.unsupportedSchemaVersion(999)) {
            try QuizPack.decode(from: data)
        }
    }

    @Test
    func validPackHasNoIssues() {
        #expect(QuizPackValidator.validate(Fixtures.pack).isEmpty)
    }

    @Test
    func detectsInvalidQuestions() {
        var pack = Fixtures.pack
        pack.questions += [
            QuizQuestion(id: "q1", categoryID: "fruit", text: "重複", choices: ["A", "B"], answerIndex: 0),
            QuizQuestion(id: "bad id", categoryID: "unknown", text: " ", choices: ["A"], answerIndex: 3),
            QuizQuestion(id: "q9", categoryID: "fruit", text: "同じ選択肢", choices: ["A", "A "], answerIndex: 0)
        ]
        let messages = QuizPackValidator.validate(pack).errors.map(\.description)
        #expect(messages == [
            "[error] 問題 q1: id が重複しています",
            "[error] 問題 bad id: id は半角英数字・ハイフン・アンダースコアで指定してください",
            "[error] 問題 bad id: 存在しないカテゴリ「unknown」を指定しています",
            "[error] 問題 bad id: 問題文が空です",
            "[error] 問題 bad id: 選択肢は 2〜6 個にしてください（現在 1 個）",
            "[error] 問題 bad id: 正解の番号 4 に対応する選択肢がありません",
            "[error] 問題 q9: 同じ内容の選択肢があります"
        ])
    }

    @Test
    func warnsEmptyCategory() {
        var pack = Fixtures.pack
        pack.categories.append(QuizCategory(id: "empty", name: "空"))
        #expect(QuizPackValidator.validate(pack).map(\.description) == ["[warning] カテゴリ empty: 問題が 1 問もありません"])
    }
}
