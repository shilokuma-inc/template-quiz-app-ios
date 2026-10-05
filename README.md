# QuizTemplateApp

Quiz App Template for iOS (SwiftUI)

クイズアプリを量産するための GitHub テンプレートリポジトリです。
[template-app-ios](https://github.com/shilokuma-inc/template-app-ios) をベースに、SwiftUI のプロジェクト一式と、ビルド・テスト・Archive・TestFlight 配信までの GitHub Actions ワークフローを含みます。

## Environment

- Xcode 26.3
- iOS 17.0 以上
- Swift 6（Swift 6 言語モード / Strict Concurrency）
- SwiftUI / Swift Testing / XCTest（UI テスト）
- SwiftLint 0.65.1（Build Tool Plugin）

## Status

<div style="margin:0px;padding:0px;">
  <table width="98%" style="border-collapse: collapse;border:2px double #000080;text-align:center;margin:auto;">
    <tbody>
      <tr>
        <td style="border:2px double #000080;">branch \ workflow</td>
        <td style="border:2px double #000080;">Build</td>
        <td style="border:2px double #000080;">Archive</td>
        <td style="border:2px double #000080;">Upload</td>
      </tr>
      <tr>
        <td style="border:2px double #000080;text-align:left;">main</td>
        <td style="border:2px double #000080;text-align:center;">
          <a href="https://github.com/shilokuma-inc/template-quiz-app-ios/actions/workflows/build.yml?query=branch%3Amain">
            <img src="https://github.com/shilokuma-inc/template-quiz-app-ios/actions/workflows/build.yml/badge.svg?branch=main" alt="Build">
          </a>
        </td>
        <td style="border:2px double #000080;text-align:center;">
          <a href="https://github.com/shilokuma-inc/template-quiz-app-ios/actions/workflows/archive.yml?query=branch%3Amain">
            <img src="https://github.com/shilokuma-inc/template-quiz-app-ios/actions/workflows/archive.yml/badge.svg?branch=main" alt="Archive">
          </a>
        </td>
        <td style="border:2px double #000080;text-align:center;">
        </td>
      </tr>
      <tr>
        <td style="border:2px double #000080;text-align:left;">develop</td>
        <td style="border:2px double #000080;text-align:center;">
          <a href="https://github.com/shilokuma-inc/template-quiz-app-ios/actions/workflows/build.yml?query=branch%3Adevelop">
            <img src="https://github.com/shilokuma-inc/template-quiz-app-ios/actions/workflows/build.yml/badge.svg?branch=develop" alt="Build">
          </a>
        </td>
        <td style="border:2px double #000080;text-align:center;">
        </td>
        <td style="border:2px double #000080;text-align:center;">
          <a href="https://github.com/shilokuma-inc/template-quiz-app-ios/actions/workflows/upload.yml?query=branch%3Adevelop">
            <img src="https://github.com/shilokuma-inc/template-quiz-app-ios/actions/workflows/upload.yml/badge.svg?branch=develop" alt="Upload">
          </a>
        </td>
      </tr>
    </tbody>
  </table>
</div>

## このテンプレートでできること

アプリの大枠（画面・出題ロジック・成績・設定・広告の差し込み口）は共通の Swift Package **QuizKit** が持ち、
**問題データ（CSV）とテーマ（色・文言・画像）を差し替えるだけ**で別のクイズアプリとしてリリースできます。

| ホーム | 出題 | 結果 | 設定 |
|---|---|---|---|
| カテゴリ別の習得状況、ランダム出題、間違えた問題の復習 | 選択肢シャッフル、正誤フィードバック、解説、振動 | 正答率、ふりかえり、間違えた問題に再挑戦 | 出題数、シャッフル、振動、学習記録のリセット、各種リンク |

アプリごとに差し替えるのは次の 4 か所だけです。設計の詳細は [docs/architecture.md](docs/architecture.md) を参照してください。

| 差し替える場所 | 内容 |
|---|---|
| [Content/](Content)（`categories.csv` / `questions.csv`） | 問題・カテゴリ。外部委託で作成してもらう（入稿ルール: [docs/quiz-content.md](docs/quiz-content.md)） |
| [QuizTemplateApp/AppConfiguration.swift](QuizTemplateApp/AppConfiguration.swift) | キャッチコピー・テーマ・出題数・プライバシーポリシー等のリンク・広告 |
| [QuizTemplateApp/Assets.xcassets](QuizTemplateApp/Assets.xcassets) | テーマカラー（`Theme/`）・アプリアイコン・画像 |
| [Configs/Project.xcconfig](Configs/Project.xcconfig) | Bundle ID・アプリ名（`APP_DISPLAY_NAME`）・バージョン |

## 新しいクイズアプリの作り方

1. 下記「テンプレートの使い方」の 1〜4 でリポジトリ・署名・Secrets を用意する
2. [Configs/Project.xcconfig](Configs/Project.xcconfig) の `APP_DISPLAY_NAME` をアプリ名にする
3. [Content/](Content) の CSV を納品された問題に差し替え、変換する
   ```bash
   scripts/import-quiz.sh
   ```
   エラーが出たら行番号を見て CSV を直します。生成された `QuizTemplateApp/Resources/quiz.json` もコミットします
4. [AppConfiguration.swift](QuizTemplateApp/AppConfiguration.swift) のキャッチコピー・リンク・出題数を書き換える
   - プライバシーポリシーの URL は App Store の審査で必須です
5. `Assets.xcassets/Theme` の `ThemePrimary` / `ThemeBackground` / `ThemeSurface`（と `AccentColor`）、`AppIcon` を差し替える
   - ホーム上部の画像を変えるときは画像を追加して `heroImageName` に指定します
6. 広告を出す場合は `AdProvider` を実装して `ads` に渡す（[docs/architecture.md](docs/architecture.md#広告)）
7. シミュレータで一通り操作し、テストが通ることを確認してリリースする

## テンプレートの使い方

### 1. リポジトリを作成する

GitHub の「Use this template」からリポジトリを作成し、clone します。

### 2. プロジェクト名を変更する

`QuizTemplateApp` を新しいアプリ名に一括変更するスクリプトを用意しています。
ディレクトリ・`.xcodeproj`・スキーム・ソース内の識別子・README のバッジ URL をまとめて置換します。

```bash
scripts/rename.sh MyApp
```

- アプリ名は英字で始まる英数字のみです（Swift のモジュール名になります）。ホーム画面に表示するアプリ名は `APP_DISPLAY_NAME` で別に指定します
- 共通部分の `Packages/QuizKit` は名前を変えません
- README のバッジ URL に使うリポジトリ名は `origin` から推定します。別のものを使う場合は第 2 引数で `owner/repo` を渡します
- 作業ツリーがクリーンな状態で実行し、実行後に `git diff` で差分を確認してコミットしてください

### 3. 署名情報を設定する

署名情報やバージョンは pbxproj ではなく [Configs/Project.xcconfig](Configs/Project.xcconfig) に集約しています。
リポジトリ作成後、まず以下を書き換えてください。

| 設定 | 内容 |
|---|---|
| `DEVELOPMENT_TEAM` | Apple Developer Program の Team ID |
| `APP_BUNDLE_IDENTIFIER` | アプリ本体の Bundle Identifier。テストターゲットは `.Tests` / `.UITests` を付けて自動で派生します |
| `APP_DISPLAY_NAME` | ホーム画面に表示するアプリ名。アプリ内のタイトルにも使います |
| `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` | アプリのバージョン / ビルド番号 |
| `IPHONEOS_DEPLOYMENT_TARGET` | 最低サポート OS |

### 4. GitHub Secrets を設定する

Archive / Upload ワークフローは App Store Connect API Key で認証します。
リポジトリの Settings → Secrets and variables → Actions に以下を登録してください。

| Secret | 内容 |
|---|---|
| `EXPORT_OPTIONS` | `ExportOptions.plist` の内容。[docs/ExportOptions.sample.plist](docs/ExportOptions.sample.plist) の `teamID` を書き換えて、ファイルの中身をそのまま登録します |
| `APPLE_API_KEY_BASE64` | App Store Connect の API Key（`AuthKey_XXXXXXXXXX.p8`）を `base64 -i AuthKey_XXXXXXXXXX.p8` でエンコードした文字列 |
| `APPLE_API_KEY_ID` | API Key の Key ID |
| `APPLE_API_ISSUER_ID` | API Key の Issuer ID |

API Key は App Store Connect の「ユーザとアクセス → 統合 → App Store Connect API」で、App Manager 以上の権限で発行します。
アップロード先のアプリは事前に App Store Connect に登録しておいてください。

### 5. ブランチ運用と CI

| ブランチ | Build（ビルド + テスト + SwiftLint + 問題データの検証） | Archive（IPA Export） | Upload（App Store Connect） |
|---|:-:|:-:|:-:|
| `main` | ✅ | ✅ | |
| `develop` | ✅ | | ✅ |
| `release/**` | ✅ | | ✅ |
| その他の作業ブランチ | ✅ | | |
| `assets/**`（スクリーンショット置き場） | | | |
| Fork からの Pull Request | ✅ | | |

- Upload は Archive → IPA Export を含むため、`develop` / `release/**` では Archive を別途実行しません
- `assets/**` はアプリのコードを含まないため、どのワークフローも実行しません
- リポジトリ変数（Settings → Secrets and variables → Actions → Variables）に `ENABLE_DELIVERY=false` を設定すると Archive / Upload をスキップします。テンプレートリポジトリ自身はこの設定で配信を止めています。テンプレートから作成したリポジトリには引き継がれないため、何もしなければ従来どおり実行されます
- Xcode のバージョンは [.github/workflows/_build.yml](.github/workflows/_build.yml) と [.github/workflows/_archive.yml](.github/workflows/_archive.yml) の `xcode-version` で固定しています。Environment の更新時はあわせて変更してください

### 6. PR 本文のスクリーンショット

UI の見た目が変わる変更では、Before / After のスクリーンショットを PR 本文に添付します。

- 画像は PR の diff を汚さないよう **`assets/issue-<Issue番号>` ブランチ**に置き、PR 本文からは raw URL で参照します
  - 例: `https://raw.githubusercontent.com/<owner>/<repo>/assets/issue-12/12/before.png`
  - このブランチは [.github/workflows/cleanup-assets-branch.yml](.github/workflows/cleanup-assets-branch.yml) が PR のマージ時に自動削除します。ブランチ名がこの規約から外れると削除されないので注意してください
- Before / After は表で横に並べ、同一条件（同じ端末・OS・外観モード・データ状態）で撮影します
- 影響する画面が複数ある場合は画面ごとに用意します。新規画面で Before が無い場合は「なし」と書きます

## 構成

```
.
├── Configs/                  # xcconfig（署名情報・アプリ名・バージョン・Deployment Target）
├── Content/                  # 問題の原本（categories.csv / questions.csv）
├── Packages/QuizKit/         # クイズの共通部分（QuizCore / QuizUI / quiz-tool）
├── QuizTemplateApp/          # アプリ本体。AppConfiguration.swift・Assets・Resources/quiz.json（生成物）
├── QuizTemplateAppTests/     # Unit テスト（Swift Testing）。同梱した問題データの検証を含む
├── QuizTemplateAppUITests/   # UI テスト（XCTest）
├── QuizTemplateApp.xcodeproj # 共有スキーム QuizTemplateApp を含む（QuizCoreTests も実行する）
├── docs/                     # 設計・問題の入稿ルール・ExportOptions.plist のサンプル
├── scripts/                  # rename.sh / import-quiz.sh
├── .swiftlint.yml            # SwiftLint 設定
└── .github/
    ├── ISSUE_TEMPLATE/       # Issue テンプレート
    ├── pull_request_template.md
    └── workflows/
        ├── _build.yml        # 共通処理: ビルド + テスト + SwiftLint（workflow_call）
        ├── _archive.yml      # 共通処理: Archive → Export（→ Upload）（workflow_call）
        ├── build.yml         # 全ブランチの push / Fork からの PR
        ├── archive.yml       # main の push
        ├── upload.yml        # develop / release/** の push
        ├── cleanup-assets-branch.yml # PR マージ時に assets/issue-<番号> ブランチを削除
        └── close-goal-discussion.yml # epic の最終 PR のマージ時にゴール元の Discussion を閉じる
```

- プロジェクトはフォルダ同期グループ（Xcode 16 以降の形式）で管理しているため、ファイルの追加・削除で pbxproj は変わりません
- SwiftLint は Build Tool Plugin として全ターゲットに適用され、CI では `swiftlint lint --strict` としても実行されます。ルールは [.swiftlint.yml](.swiftlint.yml) で管理します
- CI のワークフローは `*.xcodeproj` の名前と同名の共有スキームが存在することを前提にしています

## License

[MIT License](LICENSE)
