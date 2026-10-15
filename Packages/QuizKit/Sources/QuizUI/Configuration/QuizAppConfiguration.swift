import Foundation
import QuizCore

/// アプリごとに差し替える設定一式。アプリ側の `AppConfiguration.swift` で組み立てて `QuizRootView` に渡す
@MainActor
public struct QuizAppConfiguration {
    /// ホーム画面に出すアプリ名。既定はホーム画面のアイコン名（CFBundleDisplayName）
    public var appName: String
    /// アプリ名の下に出すキャッチコピー
    public var tagline: String?
    public var theme: QuizTheme
    public var contentProvider: any QuizContentProvider
    /// 設定画面で選べる出題数（「すべて」は常に選べる）
    public var questionCountOptions: [Int]
    /// 出題数の初期値。nil なら「すべて」
    public var defaultQuestionCount: Int?
    public var links: Links
    public var ads: AdConfiguration

    public init(
        appName: String = Bundle.main.quizDisplayName,
        tagline: String? = nil,
        theme: QuizTheme = .standard,
        contentProvider: any QuizContentProvider = BundleQuizContentProvider(),
        questionCountOptions: [Int] = [5, 10, 20],
        defaultQuestionCount: Int? = 10,
        links: Links = Links(),
        ads: AdConfiguration = .none
    ) {
        self.appName = appName
        self.tagline = tagline
        self.theme = theme
        self.contentProvider = contentProvider
        self.questionCountOptions = questionCountOptions
        self.defaultQuestionCount = defaultQuestionCount
        self.links = links
        self.ads = ads
    }

    /// 設定画面に出すリンク。nil の項目は表示しない
    public struct Links: Sendable {
        /// プライバシーポリシー（App Store の審査で必須。広告を出す場合は広告 SDK の扱いも記載する）
        public var privacyPolicy: URL?
        public var termsOfUse: URL?
        /// お問い合わせ（フォームの URL や mailto:）
        public var support: URL?

        public init(privacyPolicy: URL? = nil, termsOfUse: URL? = nil, support: URL? = nil) {
            self.privacyPolicy = privacyPolicy
            self.termsOfUse = termsOfUse
            self.support = support
        }
    }
}

extension Bundle {
    /// ホーム画面のアイコン名（CFBundleDisplayName → CFBundleName の順に探す）
    public var quizDisplayName: String {
        (object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? ""
    }

    /// 設定画面に出すバージョン表記（例: 1.0.0 (1)）
    public var quizVersionText: String {
        let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
        let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
        return "\(version) (\(build))"
    }
}
