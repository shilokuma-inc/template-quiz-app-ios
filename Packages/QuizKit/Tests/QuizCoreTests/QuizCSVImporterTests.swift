@testable import QuizCore
import Testing

struct QuizCSVImporterTests {
    private let categoriesCSV = """
        id,name,summary,icon,memo
        fruit,くだもの,果物の問題,leaf,委託先のメモ
        """

    @Test
    func importsQuestionsByHeaderName() throws {
        // 列の順番は自由、未知の列（memo）は無視する
        let questionsCSV = """
            memo,answer,question,id,category_id,choice_1,choice_2,choice_3,explanation,fixed_order
            確認済み,２,"黄色い果物は？",q1,fruit,りんご,バナナ,,バナナは黄色い,
            ,3,どれ？,q2,fruit,A,B,上記すべて,,○

            """
        let pack = try QuizCSVImporter.makePack(categoriesCSV: categoriesCSV, questionsCSV: questionsCSV)

        #expect(pack.categories == [QuizCategory(id: "fruit", name: "くだもの", summary: "果物の問題", iconSystemName: "leaf")])
        #expect(pack.questions == [
            QuizQuestion(id: "q1", categoryID: "fruit", text: "黄色い果物は？", choices: ["りんご", "バナナ"], answerIndex: 1, explanation: "バナナは黄色い"),
            QuizQuestion(id: "q2", categoryID: "fruit", text: "どれ？", choices: ["A", "B", "上記すべて"], answerIndex: 2, keepsChoiceOrder: true)
        ])
    }

    @Test
    func reportsMissingColumnsAndInvalidAnswerWithLineNumbers() {
        let questionsCSV = """
            id,category_id,question,choice_1,choice_2,answer
            q1,fruit,問題,A,B,A
            """
        #expect {
            try QuizCSVImporter.makePack(categoriesCSV: "id\nfruit", questionsCSV: questionsCSV)
        } throws: { error in
            let issues = (error as? QuizCSVImporter.ImportError)?.issues ?? []
            return issues.map(\.description) == [
                "categories.csv:1: 必須の列がありません: name",
                "questions.csv:2: answer は正解の選択肢の番号（1〜6）で指定してください: \"A\""
            ]
        }
    }

    @Test
    func reportsRowsWithMoreFieldsThanHeader() {
        // 解説の「3,776m」をクォートし忘れて列がずれたケース
        let questionsCSV = """
            id,category_id,question,choice_1,choice_2,answer,explanation
            q1,fruit,問題,A,B,1,標高は 3,776m
            """
        #expect {
            try QuizCSVImporter.makePack(categoriesCSV: categoriesCSV, questionsCSV: questionsCSV)
        } throws: { error in
            let issues = (error as? QuizCSVImporter.ImportError)?.issues ?? []
            return issues.map(\.description) == [
                "questions.csv:2: 列の数がヘッダーより多くなっています。カンマを含むセルは \"\" で囲んでください"
            ]
        }
    }

    @Test
    func reportsEmptyChoiceBeforeFilledChoice() {
        // choice_2 を空けたケース。詰めると answer の 3 が「C」ではなく「D」を指してしまう
        let questionsCSV = """
            id,category_id,question,choice_1,choice_2,choice_3,choice_4,answer
            q1,fruit,問題,A,,C,D,3
            """
        #expect {
            try QuizCSVImporter.makePack(categoriesCSV: categoriesCSV, questionsCSV: questionsCSV)
        } throws: { error in
            let issues = (error as? QuizCSVImporter.ImportError)?.issues ?? []
            return issues.map(\.description) == [
                "questions.csv:2: choice_2 が空のまま後ろの列に選択肢があります。選択肢は choice_1 から詰めて入力してください"
            ]
        }
    }
}
