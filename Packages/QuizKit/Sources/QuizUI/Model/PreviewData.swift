import QuizCore
import SwiftUI

// Xcode Preview 用のサンプル。アプリ側の Preview でも使えるよう public にしている

extension QuizPack {
    public static let preview = QuizPack(
        categories: [
            QuizCategory(id: "science", name: "理科", summary: "身近な自然と科学", iconSystemName: "atom"),
            QuizCategory(id: "history", name: "歴史", summary: "日本の歴史", iconSystemName: "building.columns")
        ],
        questions: [
            QuizQuestion(
                id: "science-001",
                categoryID: "science",
                text: "水が沸騰する温度は、1 気圧のもとで約何℃？",
                choices: ["100℃", "80℃", "120℃", "90℃"],
                answerIndex: 0,
                explanation: "1 気圧（標準大気圧）では、水は約 100℃ で沸騰します。"
            ),
            QuizQuestion(
                id: "science-002",
                categoryID: "science",
                text: "太陽系で最も大きい惑星は？",
                choices: ["土星", "木星", "海王星", "地球"],
                answerIndex: 1
            ),
            QuizQuestion(
                id: "history-001",
                categoryID: "history",
                text: "江戸幕府を開いたのは？",
                choices: ["徳川家康", "織田信長", "豊臣秀吉", "足利尊氏"],
                answerIndex: 0,
                explanation: "徳川家康が 1603 年に征夷大将軍となり、江戸幕府を開きました。"
            )
        ]
    )
}

extension QuizAppConfiguration {
    public static var preview: QuizAppConfiguration {
        QuizAppConfiguration(
            appName: "サンプルクイズ",
            tagline: "Preview 用のクイズです",
            contentProvider: StaticQuizContentProvider(pack: .preview),
            links: Links(privacyPolicy: URL(string: "https://example.com/privacy")),
            ads: AdConfiguration(provider: PlaceholderAdProvider())
        )
    }
}

extension QuizAppModel {
    /// 問題データを読み込み済みの状態
    static var preview: QuizAppModel {
        let model = QuizAppModel(configuration: .preview, storage: InMemoryQuizStorage())
        model.setLoadedPackForPreview(.preview)
        return model
    }
}
