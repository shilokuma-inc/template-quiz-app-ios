import Foundation
import Observation
import QuizCore

/// アプリ全体の状態（問題データ・学習記録・設定）
@MainActor
@Observable
public final class QuizAppModel {
    public enum LoadState {
        case loading
        case loaded(QuizPack)
        case failed(String)
    }

    public let configuration: QuizAppConfiguration
    public private(set) var loadState: LoadState = .loading
    public private(set) var progress: QuizProgress
    public var settings: QuizSettings {
        didSet {
            storage.save(settings, forKey: QuizStorageKey.settings)
        }
    }

    private let storage: any QuizStorage
    /// 前回インタースティシャルを出してから解き終えた回数
    private var completedSinceInterstitial = 0

    public init(configuration: QuizAppConfiguration, storage: any QuizStorage) {
        self.configuration = configuration
        self.storage = storage
        progress = storage.load(QuizProgress.self, forKey: QuizStorageKey.progress) ?? QuizProgress()
        settings = storage.load(QuizSettings.self, forKey: QuizStorageKey.settings)
            ?? QuizSettings(questionCount: configuration.defaultQuestionCount)
    }

    public var pack: QuizPack? {
        if case let .loaded(pack) = loadState {
            return pack
        }
        return nil
    }

    public func load() async {
        loadState = .loading
        do {
            loadState = try await .loaded(configuration.contentProvider.loadPack())
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    /// 出題数・シャッフルは設定画面の値に従う。復習（`.questions`）は対象をすべて出題する
    public func makeSession(scope: QuizSessionRequest.Scope) -> QuizSession? {
        guard let pack else {
            return nil
        }
        let questionCount: Int? = if case .questions = scope { nil } else { settings.questionCount }
        let request = QuizSessionRequest(
            scope: scope,
            questionCount: questionCount,
            shufflesChoices: settings.shufflesChoices
        )
        return QuizSession(pack: pack, request: request)
    }

    /// 同じ条件でもう一度出題する
    public func makeSession(repeating request: QuizSessionRequest) -> QuizSession? {
        pack.flatMap { QuizSession(pack: $0, request: request) }
    }

    public var incorrectQuestionIDs: [QuizQuestion.ID] {
        pack.map { progress.incorrectQuestionIDs(in: $0) } ?? []
    }

    /// 回答結果を学習記録に保存する
    /// - Parameter completed: 最後まで解いたか（途中でやめた場合も回答済みの問題は記録する）
    public func record(_ result: QuizResult, completed: Bool) {
        guard !result.answeredEntries.isEmpty else {
            return
        }
        progress.record(result, completed: completed)
        storage.save(progress, forKey: QuizStorageKey.progress)
        if completed {
            completedSinceInterstitial += 1
        }
    }

    /// 解き終えた回数が設定の間隔に達していればインタースティシャル広告を出す
    public func presentInterstitialIfNeeded() async {
        let interval = configuration.ads.interstitialInterval
        guard interval > 0, completedSinceInterstitial >= interval else {
            return
        }
        completedSinceInterstitial = 0
        await configuration.ads.provider.presentInterstitial()
    }

    /// Preview 用: 問題データを読み込み済みにする
    func setLoadedPackForPreview(_ pack: QuizPack) {
        loadState = .loaded(pack)
    }

    public func resetProgress() {
        progress = QuizProgress()
        storage.removeValue(forKey: QuizStorageKey.progress)
    }
}
