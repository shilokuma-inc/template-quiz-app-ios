import Foundation

/// 1 回分の出題条件
public struct QuizSessionRequest: Sendable, Hashable {
    public enum Scope: Sendable, Hashable {
        /// すべての問題から出題する
        case all
        /// 指定したカテゴリから出題する
        case category(QuizCategory.ID)
        /// 指定した問題だけを出題する（間違えた問題の復習など）
        case questions([QuizQuestion.ID])
    }

    public var scope: Scope
    /// 出題数の上限。nil なら対象の問題をすべて出題する
    public var questionCount: Int?
    public var shufflesQuestions: Bool
    public var shufflesChoices: Bool

    public init(scope: Scope, questionCount: Int? = nil, shufflesQuestions: Bool = true, shufflesChoices: Bool = true) {
        self.scope = scope
        self.questionCount = questionCount
        self.shufflesQuestions = shufflesQuestions
        self.shufflesChoices = shufflesChoices
    }
}

/// 出題中の状態。画面から独立した値型にしておき、ロジックを Unit テストで確認できるようにする
public struct QuizSession: Sendable, Equatable {
    /// 出題する 1 問。選択肢は表示順に並べ替え済み
    public struct Item: Sendable, Hashable, Identifiable {
        public var question: QuizQuestion
        /// 表示位置 → 元の選択肢の位置
        public var choiceOrder: [Int]

        public var id: QuizQuestion.ID { question.id }

        public var displayedChoices: [String] {
            choiceOrder.map { question.choices[$0] }
        }

        /// 正解の選択肢の表示位置
        public var correctDisplayIndex: Int {
            choiceOrder.firstIndex(of: question.answerIndex) ?? 0
        }
    }

    public let request: QuizSessionRequest
    public let items: [Item]
    public private(set) var currentIndex = 0
    /// 各問で選んだ選択肢の表示位置（未回答は nil）
    public private(set) var selections: [Int?]

    public init(request: QuizSessionRequest, items: [Item]) {
        self.request = request
        self.items = items
        self.selections = Array(repeating: nil, count: items.count)
    }

    /// 条件に合う問題を選んでセッションを作る。対象の問題が 1 問もなければ nil
    public init?(pack: QuizPack, request: QuizSessionRequest) {
        var generator = SystemRandomNumberGenerator()
        self.init(pack: pack, request: request, using: &generator)
    }

    public init?(pack: QuizPack, request: QuizSessionRequest, using generator: inout some RandomNumberGenerator) {
        var questions: [QuizQuestion]
        switch request.scope {
        case .all:
            questions = pack.questions

        case let .category(categoryID):
            questions = pack.questions(in: categoryID)

        case let .questions(ids):
            let byID = Dictionary(pack.questions.map { ($0.id, $0) }) { first, _ in first }
            questions = ids.compactMap { byID[$0] }
        }

        if request.shufflesQuestions {
            questions.shuffle(using: &generator)
        }
        if let count = request.questionCount {
            questions = Array(questions.prefix(max(count, 0)))
        }
        guard !questions.isEmpty else {
            return nil
        }

        let items = questions.map { question in
            var order = Array(question.choices.indices)
            if request.shufflesChoices, !question.keepsChoiceOrder {
                order.shuffle(using: &generator)
            }
            return Item(question: question, choiceOrder: order)
        }
        self.init(request: request, items: items)
    }

    public var currentItem: Item? {
        items.indices.contains(currentIndex) ? items[currentIndex] : nil
    }

    public var isFinished: Bool {
        currentIndex >= items.count
    }

    public var currentSelection: Int? {
        selections.indices.contains(currentIndex) ? selections[currentIndex] : nil
    }

    public var isLastItem: Bool {
        currentIndex == items.count - 1
    }

    /// 現在の問題に回答する。回答済みの問題に再度回答しても結果は変わらない
    /// - Returns: 正解なら true
    @discardableResult
    public mutating func answer(displayIndex: Int) -> Bool {
        guard let item = currentItem, item.choiceOrder.indices.contains(displayIndex) else {
            return false
        }
        if selections[currentIndex] == nil {
            selections[currentIndex] = displayIndex
        }
        return selections[currentIndex] == item.correctDisplayIndex
    }

    /// 次の問題へ進む。未回答のままでは進めない
    public mutating func advance() {
        guard !isFinished, currentSelection != nil else {
            return
        }
        currentIndex += 1
    }

    public var result: QuizResult {
        QuizResult(
            entries: zip(items, selections).map { item, selection in
                QuizResult.Entry(
                    question: item.question,
                    selectedChoiceIndex: selection.map { item.choiceOrder[$0] }
                )
            }
        )
    }
}

/// 1 回分の結果
public struct QuizResult: Sendable, Hashable {
    public struct Entry: Sendable, Hashable, Identifiable {
        public var question: QuizQuestion
        /// 選んだ選択肢の元の位置（未回答は nil）
        public var selectedChoiceIndex: Int?

        public var id: QuizQuestion.ID { question.id }

        public var isAnswered: Bool {
            selectedChoiceIndex != nil
        }

        public var isCorrect: Bool {
            selectedChoiceIndex == question.answerIndex
        }

        public var selectedChoice: String? {
            selectedChoiceIndex.flatMap { question.choices.indices.contains($0) ? question.choices[$0] : nil }
        }
    }

    public var entries: [Entry]

    public init(entries: [Entry]) {
        self.entries = entries
    }

    public var answeredEntries: [Entry] {
        entries.filter(\.isAnswered)
    }

    public var correctCount: Int {
        entries.count(where: \.isCorrect)
    }

    public var totalCount: Int {
        entries.count
    }

    /// 正答率（0〜1）
    public var accuracy: Double {
        totalCount == 0 ? 0 : Double(correctCount) / Double(totalCount)
    }

    public var incorrectQuestionIDs: [QuizQuestion.ID] {
        entries.filter { $0.isAnswered && !$0.isCorrect }.map(\.id)
    }
}
