import QuizCore
import SwiftUI

/// アプリのルート画面。アプリ側の `App` からこの View に設定を渡すだけで、クイズアプリ一式が動く
public struct QuizRootView: View {
    /// UI テストで学習記録・設定を保存しないようにする起動引数
    public static let uiTestingLaunchArgument = "-QuizUITesting"

    @State private var model: QuizAppModel

    /// - Parameter storage: 学習記録・設定の保存先。省略時は UserDefaults（UI テスト時はメモリ上）
    public init(configuration: QuizAppConfiguration, storage: (any QuizStorage)? = nil) {
        let storage = storage ?? Self.defaultStorage()
        _model = State(initialValue: QuizAppModel(configuration: configuration, storage: storage))
    }

    public var body: some View {
        content
            .environment(\.quizTheme, model.configuration.theme)
            .fontDesign(model.configuration.theme.fontDesign)
            .tint(model.configuration.theme.primary)
            .task {
                await model.load()
            }
            .task {
                await model.configuration.ads.provider.start()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch model.loadState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(model.configuration.theme.background)

        case .loaded:
            HomeView(model: model)

        case let .failed(message):
            ContentUnavailableView {
                Label("問題を読み込めませんでした", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("再読み込み") {
                    Task { await model.load() }
                }
            }
        }
    }

    private static func defaultStorage() -> any QuizStorage {
        if ProcessInfo.processInfo.arguments.contains(uiTestingLaunchArgument) {
            return InMemoryQuizStorage()
        }
        return UserDefaultsQuizStorage()
    }
}

#Preview {
    QuizRootView(configuration: .preview, storage: InMemoryQuizStorage())
}
