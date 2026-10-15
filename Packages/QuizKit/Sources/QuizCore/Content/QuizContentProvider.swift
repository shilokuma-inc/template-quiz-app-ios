import Foundation

/// 問題データの取得元。
///
/// 現状はアプリ同梱の JSON を読む `BundleQuizContentProvider` のみ。
/// アプリの更新なしで問題を差し替えたくなったら、サーバーから取得してキャッシュする実装を追加し、
/// 取得失敗時は同梱データにフォールバックする構成にする想定。
public protocol QuizContentProvider: Sendable {
    func loadPack() async throws -> QuizPack
}

public enum QuizContentError: LocalizedError, Equatable {
    case resourceNotFound(String)
    case invalidContent([String])

    public var errorDescription: String? {
        switch self {
        case let .resourceNotFound(name):
            "問題データ \(name) が見つかりません"
        case let .invalidContent(messages):
            (["問題データに誤りがあります"] + messages).joined(separator: "\n")
        }
    }
}

/// アプリに同梱した `quiz.json`（`quiz-tool import` の出力）を読み込む
public struct BundleQuizContentProvider: QuizContentProvider {
    private let url: URL?
    private let resourceName: String

    public init(bundle: Bundle = .main, resourceName: String = "quiz") {
        self.url = bundle.url(forResource: resourceName, withExtension: "json")
        self.resourceName = resourceName
    }

    public func loadPack() async throws -> QuizPack {
        guard let url else {
            throw QuizContentError.resourceNotFound("\(resourceName).json")
        }
        let pack = try QuizPack.decode(from: Data(contentsOf: url))
        let errors = QuizPackValidator.validate(pack).errors
        guard errors.isEmpty else {
            throw QuizContentError.invalidContent(errors.map(\.description))
        }
        return pack
    }
}

/// メモリ上の問題データをそのまま返す（Preview・テスト用）
public struct StaticQuizContentProvider: QuizContentProvider {
    public var pack: QuizPack

    public init(pack: QuizPack) {
        self.pack = pack
    }

    public func loadPack() async throws -> QuizPack {
        pack
    }
}
