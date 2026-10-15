import SwiftUI

/// アプリごとに差し替える見た目。
///
/// 色はアプリ側の Asset Catalog に定義し（ダークモード対応もそこで行う）、
/// `AppConfiguration.swift` で `QuizTheme(primary: .themePrimary, ...)` のように渡す。
public struct QuizTheme: Sendable {
    /// ボタン・進捗バーなどのメインカラー
    public var primary: Color
    /// `primary` の上に載せる文字色
    public var onPrimary: Color
    /// 画面の背景色
    public var background: Color
    /// カード・選択肢ボタンの背景色
    public var surface: Color
    public var correct: Color
    public var incorrect: Color
    public var fontDesign: Font.Design
    public var cornerRadius: CGFloat
    /// ホーム画面の上部に出す画像（アプリの Asset Catalog の画像名）。nil なら `heroSystemImage` を使う
    public var heroImageName: String?
    /// `heroImageName` が無いときに出す SF Symbols の名前
    public var heroSystemImage: String

    public init(
        primary: Color = .accentColor,
        onPrimary: Color = .white,
        background: Color = QuizTheme.systemBackground,
        surface: Color = QuizTheme.systemSurface,
        correct: Color = .green,
        incorrect: Color = .red,
        fontDesign: Font.Design = .rounded,
        cornerRadius: CGFloat = 16,
        heroImageName: String? = nil,
        heroSystemImage: String = "questionmark.bubble.fill"
    ) {
        self.primary = primary
        self.onPrimary = onPrimary
        self.background = background
        self.surface = surface
        self.correct = correct
        self.incorrect = incorrect
        self.fontDesign = fontDesign
        self.cornerRadius = cornerRadius
        self.heroImageName = heroImageName
        self.heroSystemImage = heroSystemImage
    }

    public static let standard = QuizTheme()

    #if canImport(UIKit)
    public static let systemBackground = Color(uiColor: .systemGroupedBackground)
    public static let systemSurface = Color(uiColor: .secondarySystemGroupedBackground)
    #else
    public static let systemBackground = Color(nsColor: .windowBackgroundColor)
    public static let systemSurface = Color(nsColor: .controlBackgroundColor)
    #endif
}

extension EnvironmentValues {
    @Entry public var quizTheme: QuizTheme = .standard
}
