import SwiftUI

/// 広告を出す場所
public enum AdPlacement: String, Sendable, CaseIterable {
    /// ホーム画面の下部バナー
    case homeBanner
    /// 結果画面の下部バナー
    case resultBanner
}

/// 広告 SDK の差し込み口。
///
/// QuizKit 自体は広告 SDK に依存せず、アプリ側でこのプロトコルを実装して `AdConfiguration` に渡す。
/// AdMob を使う場合は、SDK の初期化と同意取得（UMP）を `start()`、バナーを `bannerView(for:)`、
/// インタースティシャルを `presentInterstitial()` に実装する。
@MainActor
public protocol AdProvider: AnyObject {
    /// 起動時に 1 回呼ばれる。SDK の初期化・同意取得・ATT の許可ダイアログなどを行う
    func start() async

    /// バナー広告の View。広告を出さない場所では nil を返す
    func bannerView(for placement: AdPlacement) -> AnyView?

    /// インタースティシャル広告を表示し、閉じられるまで待つ。準備できていなければ何もせずに戻る
    func presentInterstitial() async

    /// 設定画面に「広告のプライバシー設定」を出すか（UMP で同意の変更が必要な地域など）
    var showsPrivacyOptions: Bool { get }

    /// 広告のプライバシー設定（同意の変更）画面を表示する
    func presentPrivacyOptions() async
}

extension AdProvider {
    public func start() async {}
    public func bannerView(for placement: AdPlacement) -> AnyView? { nil }
    public func presentInterstitial() async {}
    public var showsPrivacyOptions: Bool { false }
    public func presentPrivacyOptions() async {}
}

/// 広告を出さない
public final class NoAdProvider: AdProvider {
    public init() {}
}

/// 広告枠の位置と大きさを確認するためのダミー（開発用）。
/// 本物の広告 SDK を組み込む前に、レイアウトが広告で崩れないかを確認するのに使う
public final class PlaceholderAdProvider: AdProvider {
    public init() {}

    public func bannerView(for placement: AdPlacement) -> AnyView? {
        AnyView(
            Text("広告枠（\(placement.rawValue)）")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.gray.opacity(0.2))
                .accessibilityIdentifier("adBanner_\(placement.rawValue)")
        )
    }
}

/// 広告の出し方
@MainActor
public struct AdConfiguration {
    public var provider: any AdProvider
    /// 何回クイズを解き終えるごとにインタースティシャルを出すか。0 なら出さない
    public var interstitialInterval: Int

    public init(provider: any AdProvider = NoAdProvider(), interstitialInterval: Int = 0) {
        self.provider = provider
        self.interstitialInterval = interstitialInterval
    }

    public static var none: AdConfiguration {
        AdConfiguration()
    }
}

/// バナー広告を出す枠。広告が無い場所では何も表示しない
struct AdBannerSlot: View {
    let provider: any AdProvider
    let placement: AdPlacement
    @Environment(\.quizTheme) private var theme

    var body: some View {
        if let banner = provider.bannerView(for: placement) {
            // スクロールするコンテンツの上に重ねるため、背景を塗って下が透けないようにする
            banner
                .frame(maxWidth: .infinity)
                .background(theme.background)
        }
    }
}
