import Foundation

/// 問題ごとの学習記録
public struct QuestionRecord: Codable, Sendable, Hashable {
    public var attemptCount: Int
    public var correctCount: Int
    /// 最後に回答したときに正解したか。false の問題を「復習」の対象にする
    public var lastAnsweredCorrectly: Bool
    public var lastAnsweredAt: Date

    public init(attemptCount: Int = 0, correctCount: Int = 0, lastAnsweredCorrectly: Bool = false, lastAnsweredAt: Date) {
        self.attemptCount = attemptCount
        self.correctCount = correctCount
        self.lastAnsweredCorrectly = lastAnsweredCorrectly
        self.lastAnsweredAt = lastAnsweredAt
    }
}

/// アプリ全体の学習記録。問題の id をキーに持つため、問題データを差し替えても id が同じなら記録は引き継がれる
public struct QuizProgress: Codable, Sendable, Equatable {
    public var records: [QuizQuestion.ID: QuestionRecord]
    /// 最後まで解いた回数
    public var completedSessionCount: Int
    public var bestAccuracy: Double

    public init(records: [QuizQuestion.ID: QuestionRecord] = [:], completedSessionCount: Int = 0, bestAccuracy: Double = 0) {
        self.records = records
        self.completedSessionCount = completedSessionCount
        self.bestAccuracy = bestAccuracy
    }

    /// 回答した問題の結果を記録する。途中でやめたセッションでも、回答済みの問題は記録する
    /// - Parameter completed: 最後まで解いたセッションか
    public mutating func record(_ result: QuizResult, completed: Bool, at date: Date = .now) {
        for entry in result.answeredEntries {
            var record = records[entry.id] ?? QuestionRecord(lastAnsweredAt: date)
            record.attemptCount += 1
            if entry.isCorrect {
                record.correctCount += 1
            }
            record.lastAnsweredCorrectly = entry.isCorrect
            record.lastAnsweredAt = date
            records[entry.id] = record
        }
        if completed {
            completedSessionCount += 1
            bestAccuracy = max(bestAccuracy, result.accuracy)
        }
    }

    /// 最後に間違えた問題（問題データに存在するものだけ、問題データの順で返す）
    public func incorrectQuestionIDs(in pack: QuizPack) -> [QuizQuestion.ID] {
        pack.questions.map(\.id).filter { records[$0]?.lastAnsweredCorrectly == false }
    }

    public func summary(for questions: [QuizQuestion]) -> Summary {
        var summary = Summary(totalCount: questions.count)
        for question in questions {
            guard let record = records[question.id] else {
                continue
            }
            summary.answeredCount += 1
            summary.attemptCount += record.attemptCount
            summary.correctAttemptCount += record.correctCount
            if record.lastAnsweredCorrectly {
                summary.learnedCount += 1
            }
        }
        return summary
    }

    /// 問題の集合に対する集計
    public struct Summary: Sendable, Hashable {
        public var totalCount: Int
        /// 1 回以上回答した問題数
        public var answeredCount = 0
        /// 最後の回答が正解だった問題数
        public var learnedCount = 0
        public var attemptCount = 0
        public var correctAttemptCount = 0

        public init(totalCount: Int) {
            self.totalCount = totalCount
        }

        /// 累計の正答率（0〜1）。未回答なら nil
        public var accuracy: Double? {
            attemptCount == 0 ? nil : Double(correctAttemptCount) / Double(attemptCount)
        }

        /// 習得率（0〜1）
        public var learnedRate: Double {
            totalCount == 0 ? 0 : Double(learnedCount) / Double(totalCount)
        }
    }
}
