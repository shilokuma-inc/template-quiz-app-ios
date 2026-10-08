import Foundation

/// 学習記録・設定の保存先
public protocol QuizStorage: AnyObject {
    func load<Value: Decodable>(_ type: Value.Type, forKey key: String) -> Value?
    func save(_ value: some Encodable, forKey key: String)
    func removeValue(forKey key: String)
}

public enum QuizStorageKey {
    public static let progress = "quiz.progress.v1"
    public static let settings = "quiz.settings.v1"
}

/// UserDefaults に JSON で保存する。問題数が数千問程度までなら十分な容量・速度
public final class UserDefaultsQuizStorage: QuizStorage {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load<Value: Decodable>(_ type: Value.Type, forKey key: String) -> Value? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(type, from: data)
    }

    public func save(_ value: some Encodable, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else {
            return
        }
        defaults.set(data, forKey: key)
    }

    public func removeValue(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}

/// メモリ上だけに保存する（Preview・UI テスト用）
public final class InMemoryQuizStorage: QuizStorage {
    private var values: [String: Data] = [:]

    public init() {}

    public func load<Value: Decodable>(_ type: Value.Type, forKey key: String) -> Value? {
        values[key].flatMap { try? JSONDecoder().decode(type, from: $0) }
    }

    public func save(_ value: some Encodable, forKey key: String) {
        values[key] = try? JSONEncoder().encode(value)
    }

    public func removeValue(forKey key: String) {
        values[key] = nil
    }
}
