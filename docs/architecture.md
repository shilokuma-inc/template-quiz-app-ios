# クイズテンプレートの設計

## 方針

クイズアプリを量産するため、**アプリの大枠はすべて共通**にし、アプリごとの違いを次の 4 か所に閉じ込めます。

| 差し替える場所 | 内容 |
|---|---|
| `Content/*.csv` | 問題・カテゴリ（外部委託で作成） |
| `QuizTemplateApp/AppConfiguration.swift` | キャッチコピー・テーマ・出題数・リンク・広告 |
| `QuizTemplateApp/Assets.xcassets` | テーマカラー（`Theme/`）・アプリアイコン・画像 |
| `Configs/Project.xcconfig` | Bundle ID・アプリ名・バージョン |

それ以外（画面・出題ロジック・成績・設定）は `Packages/QuizKit` にあり、アプリ側では触りません。

## 構成

```
Packages/QuizKit
├── QuizCore    Foundation のみ。UI から独立したロジック
│   ├── Models/     QuizPack / QuizCategory / QuizQuestion（quiz.json の形式）
│   ├── Content/    CSV の読み込み（CSVParser / QuizCSVImporter）、検証（QuizPackValidator）、
│   │               問題の取得元（QuizContentProvider）
│   ├── Session/    出題（QuizSession）と結果（QuizResult）
│   └── Progress/   学習記録（QuizProgress）・設定（QuizSettings）・保存先（QuizStorage）
├── QuizUI      SwiftUI の画面一式
│   ├── Views/      ルート / ホーム / 出題 / 結果 / 設定
│   ├── Theme/      QuizTheme（色・フォント・角丸・ホーム画像）
│   ├── Configuration/ QuizAppConfiguration（アプリごとの設定一式）
│   ├── Ads/        AdProvider（広告 SDK の差し込み口）
│   └── Model/      QuizAppModel（アプリ全体の状態）
└── quiz-tool   CSV → JSON の変換・検証 CLI（macOS）
```

- `QuizCore` は SwiftUI に依存しないため、出題・記録のロジックを Unit テスト（`QuizCoreTests`）で確認できます。アプリのスキームのテストにも含めています
- 問題の順番・選択肢の並びは `QuizSession` が決め、画面は状態を表示するだけにしています

## 問題データ

- 原本は CSV（`Content/`）。`scripts/import-quiz.sh` で検証してから `quiz.json` に変換し、アプリに同梱します
  - CSV はスプレッドシートで作りやすく、委託先に渡しやすい
  - JSON に変換する段階で検証を通すため、壊れたデータがアプリに入らない
  - JSON は `schemaVersion` を持つので、将来の形式変更やサーバー配信にも使える
- 成績は問題の `id` をキーに保存するため、問題を追加・修正してもアプリの更新で記録は失われません

### アプリの更新なしで問題を差し替えたくなったら

`QuizContentProvider` を実装した「サーバーから `quiz.json` を取得してキャッシュし、失敗したら同梱データを使う」Provider を追加し、
`AppConfiguration.swift` の `contentProvider` を差し替えます。画面側の変更は不要です。

## 広告

QuizKit は広告 SDK に依存しません。アプリ側で `AdProvider` を実装して `AppConfiguration.swift` の `ads` に渡します。

| 差し込み口 | 呼ばれるタイミング |
|---|---|
| `start()` | 起動時（SDK 初期化・UMP の同意取得・ATT） |
| `bannerView(for:)` | ホーム画面・結果画面の下部 |
| `presentInterstitial()` | 結果画面の表示時。`interstitialInterval` 回解き終えるごと |
| `showsPrivacyOptions` / `presentPrivacyOptions()` | 設定画面の「広告のプライバシー設定」 |

Debug ビルドでは `PlaceholderAdProvider` で広告枠の位置だけをダミー表示しています。

## 共通部分の更新をどう配るか

現状は QuizKit をテンプレートに同梱しているため、テンプレートから作ったアプリは作成時点の QuizKit のコピーを持ちます。
アプリが増えて「共通部分の修正を全アプリに反映したい」状況になったら、QuizKit を別リポジトリに切り出し、
各アプリはバージョンを指定して Swift Package として参照する構成に移行するのがおすすめです。
`Packages/QuizKit` は単体の Swift Package として完結させてあるので、ディレクトリごと移すだけで切り出せます。
