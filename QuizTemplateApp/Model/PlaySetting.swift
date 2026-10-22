//
//  PlaySetting.swift
//  QuizTemplateApp
//

import QuizCore
import SwiftUI

/// クイズの進め方
enum PlayMode: Hashable, Identifiable, Sendable {
    /// 決まった問題数を時間無制限で解く
    case practice
    /// 制限時間内にできるだけ多く解く
    case timeAttack(seconds: Int)

    var id: String {
        switch self {
        case .practice:
            return "practice"
        case .timeAttack(let seconds):
            return "timeAttack\(seconds)"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .practice:
            return "Practice"
        case .timeAttack(let seconds):
            return "Time Attack \(seconds)s"
        }
    }

    /// QuizKit に渡す進め方
    ///
    /// 解答後に正解・不正解の色を見せてから次の問題へ進む。タイムアタックはテンポを崩さないよう短くする。
    var rules: QuizRules {
        switch self {
        case .practice:
            var rules = QuizRules.practice
            rules.advanceDelay = 0.8
            return rules
        case .timeAttack(let seconds):
            var rules = QuizRules.timeAttack(seconds: seconds)
            rules.advanceDelay = 0.3
            return rules
        }
    }
}

/// 難易度。何を出すか（行の絞り込み・誤答の選び方）は `AppConfig.makeGenerator` が決める
enum Difficulty: String, CaseIterable, Identifiable, Sendable {
    case easy
    case normal
    case hard

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .easy:
            return "Easy"
        case .normal:
            return "Normal"
        case .hard:
            return "Hard"
        }
    }

    /// スコアの難易度係数
    var scoreFactor: Double {
        switch self {
        case .easy:
            return 1.0
        case .normal:
            return 1.5
        case .hard:
            return 2.0
        }
    }
}

/// ホームで選んだ 1 プレイの設定
struct PlaySetting: Hashable, Sendable {
    var mode: PlayMode
    var difficulty: Difficulty
    /// 練習の問題数。タイムアタックでは使わない
    var questionCount: Int

    static let `default` = PlaySetting(
        mode: AppConfig.modes[0],
        difficulty: AppConfig.difficulties.first { $0 == .normal } ?? AppConfig.difficulties[0],
        questionCount: AppConfig.defaultQuestionCount
    )

    /// 練習で選べる問題数。同じ問題を出さないよう、難易度の候補の数（むずかしいは 17 件など）を超える問題数は外す
    ///
    /// すべて外れたときは、候補の数をそのまま 1 つだけ選べるようにする。
    static func questionCounts(for difficulty: Difficulty) -> [Int] {
        questionCounts(poolSize: AppConfig.questionPoolSize(for: difficulty))
    }

    /// 候補が `poolSize` 件のときに選べる問題数
    static func questionCounts(poolSize: Int) -> [Int] {
        let counts = AppConfig.questionCounts.filter { $0 <= poolSize }
        return counts.isEmpty ? [poolSize] : counts
    }

    /// 難易度を変えたあとも選べる問題数にそろえたもの。選べなくなったら、選べる中でいちばん多い問題数にする
    func adjustingQuestionCount() -> PlaySetting {
        let counts = Self.questionCounts(for: difficulty)
        guard !counts.contains(questionCount) else { return self }
        var setting = self
        setting.questionCount = counts.last { $0 <= questionCount } ?? counts[0]
        return setting
    }

    /// ランキングの枠。モード × 難易度（練習は問題数も）ごとに分ける
    var leaderboardKey: String {
        switch mode {
        case .practice:
            return "\(mode.id).\(questionCount).\(difficulty.rawValue)"
        case .timeAttack:
            return "\(mode.id).\(difficulty.rawValue)"
        }
    }
}

/// ランキングの出し方
enum RankingStyle: Sendable, Equatable {
    /// 出さない
    case none
    /// 端末の中で自分と競う
    case local
    /// 端末の中に加えて Game Center でも競う。リーダーボードの ID は `leaderboardIDPrefix + leaderboardKey`（`.` は `_` に置き換える）
    case localAndGameCenter(leaderboardIDPrefix: String)

    var showsRanking: Bool {
        self != .none
    }

    /// Game Center のリーダーボードの ID。Game Center を使わなければ nil
    func gameCenterLeaderboardID(for setting: PlaySetting) -> String? {
        guard case .localAndGameCenter(let prefix) = self else { return nil }
        return prefix + setting.leaderboardKey.replacingOccurrences(of: ".", with: "_")
    }
}
