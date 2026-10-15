import SwiftUI

/// テーマのメインカラーで塗りつぶした、画面の主要な操作用ボタン
struct QuizPrimaryButtonStyle: ButtonStyle {
    @Environment(\.quizTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(theme.onPrimary)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal)
            .background(theme.primary.opacity(isEnabled ? 1 : 0.4), in: .rect(cornerRadius: theme.cornerRadius))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// カードと同じ背景色の、補助的な操作用ボタン
struct QuizSecondaryButtonStyle: ButtonStyle {
    @Environment(\.quizTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(theme.primary)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal)
            .background(theme.surface, in: .rect(cornerRadius: theme.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .strokeBorder(theme.primary.opacity(0.3), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == QuizPrimaryButtonStyle {
    static var quizPrimary: QuizPrimaryButtonStyle { QuizPrimaryButtonStyle() }
}

extension ButtonStyle where Self == QuizSecondaryButtonStyle {
    static var quizSecondary: QuizSecondaryButtonStyle { QuizSecondaryButtonStyle() }
}

/// テーマのカード背景で囲む
struct QuizCardModifier: ViewModifier {
    @Environment(\.quizTheme) private var theme

    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.surface, in: .rect(cornerRadius: theme.cornerRadius))
    }
}

extension View {
    func quizCard() -> some View {
        modifier(QuizCardModifier())
    }
}

/// 割合を示す円グラフ
struct ProgressRing: View {
    var value: Double
    var lineWidth: CGFloat = 10
    var color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(value, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

extension Double {
    /// 0〜1 の割合を「85%」のような表記にする
    var percentText: String {
        formatted(.percent.precision(.fractionLength(0)))
    }
}
