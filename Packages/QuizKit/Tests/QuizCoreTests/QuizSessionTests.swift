import Foundation
@testable import QuizCore
import Testing

struct QuizSessionTests {
    @Test
    func selectsQuestionsByScopeAndCount() throws {
        var generator = SeededGenerator(seed: 1)
        let category = try #require(QuizSession(pack: Fixtures.pack, request: .init(scope: .category("animal")), using: &generator))
        #expect(Set(category.items.map(\.id)) == ["q3", "q4"])

        let limited = try #require(QuizSession(pack: Fixtures.pack, request: .init(scope: .all, questionCount: 2), using: &generator))
        #expect(limited.items.count == 2)

        // 指定した問題は指定順のまま、存在しない id は無視する
        let review = try #require(
            QuizSession(
                pack: Fixtures.pack,
                request: .init(scope: .questions(["q3", "missing", "q1"]), shufflesQuestions: false),
                using: &generator
            )
        )
        #expect(review.items.map(\.id) == ["q3", "q1"])
    }

    @Test
    func returnsNilWhenNoQuestionsMatch() {
        #expect(QuizSession(pack: Fixtures.pack, request: .init(scope: .category("none"))) == nil)
        #expect(QuizSession(pack: Fixtures.pack, request: .init(scope: .all, questionCount: 0)) == nil)
    }

    @Test
    func shufflesChoicesButKeepsFixedOrderAndTracksCorrectAnswer() throws {
        for seed in 0..<20 {
            var generator = SeededGenerator(seed: UInt64(seed))
            let session = try #require(QuizSession(pack: Fixtures.pack, request: .init(scope: .all), using: &generator))
            for item in session.items {
                #expect(item.displayedChoices[item.correctDisplayIndex] == item.question.answer)
                if item.question.keepsChoiceOrder {
                    #expect(item.displayedChoices == item.question.choices)
                }
            }
        }
    }

    @Test
    func answersAdvancesAndBuildsResult() throws {
        var session = try #require(
            QuizSession(
                pack: Fixtures.pack,
                request: .init(scope: .questions(["q1", "q2"]), shufflesQuestions: false, shufflesChoices: false)
            )
        )
        // 未回答では進めない
        session.advance()
        #expect(session.currentIndex == 0)

        let firstIsCorrect = session.answer(displayIndex: 0)
        #expect(firstIsCorrect)
        // 回答済みの問題に答え直しても結果は変わらない
        let retriedIsCorrect = session.answer(displayIndex: 2)
        #expect(retriedIsCorrect)
        session.advance()

        let secondIsCorrect = session.answer(displayIndex: 0)
        #expect(!secondIsCorrect)
        #expect(session.isLastItem)
        session.advance()

        #expect(session.isFinished)
        #expect(session.currentItem == nil)
        let result = session.result
        #expect(result.correctCount == 1)
        #expect(result.totalCount == 2)
        #expect(result.accuracy == 0.5)
        #expect(result.incorrectQuestionIDs == ["q2"])
        #expect(result.entries[1].selectedChoice == "りんご")
    }
}

struct QuizProgressTests {
    @Test
    func recordsResultsAndSummarizes() throws {
        var session = try #require(
            QuizSession(pack: Fixtures.pack, request: .init(scope: .all, shufflesQuestions: false, shufflesChoices: false))
        )
        var progress = QuizProgress()
        // q1: 正解, q2: 不正解, q3 以降は未回答のまま中断
        session.answer(displayIndex: 0)
        session.advance()
        session.answer(displayIndex: 0)
        progress.record(session.result, completed: false)

        #expect(progress.records.keys.sorted() == ["q1", "q2"])
        #expect(progress.completedSessionCount == 0)
        #expect(progress.incorrectQuestionIDs(in: Fixtures.pack) == ["q2"])

        let summary = progress.summary(for: Fixtures.pack.questions(in: "fruit"))
        #expect(summary.answeredCount == 2)
        #expect(summary.learnedCount == 1)
        #expect(summary.accuracy == 0.5)
        #expect(summary.learnedRate == 0.5)

        // 次の回で q2 に正解すると復習対象から外れる
        let retry = QuizResult(entries: [.init(question: Fixtures.pack.questions[1], selectedChoiceIndex: 1)])
        progress.record(retry, completed: true)
        #expect(progress.incorrectQuestionIDs(in: Fixtures.pack).isEmpty)
        #expect(progress.records["q2"]?.attemptCount == 2)
        #expect(progress.completedSessionCount == 1)
        #expect(progress.bestAccuracy == 1)
    }

    @Test
    func storesValuesInStorage() {
        let storage = InMemoryQuizStorage()
        let settings = QuizSettings(questionCount: nil, shufflesChoices: false, hapticsEnabled: true)
        storage.save(settings, forKey: QuizStorageKey.settings)
        #expect(storage.load(QuizSettings.self, forKey: QuizStorageKey.settings) == settings)
        storage.removeValue(forKey: QuizStorageKey.settings)
        #expect(storage.load(QuizSettings.self, forKey: QuizStorageKey.settings) == nil)
    }

    @Test
    func decodesOldSettingsWithDefaults() throws {
        let settings = try JSONDecoder().decode(QuizSettings.self, from: Data(#"{"questionCount":5}"#.utf8))
        #expect(settings == QuizSettings(questionCount: 5, shufflesChoices: true, hapticsEnabled: true))
    }
}
