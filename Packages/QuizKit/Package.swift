// swift-tools-version: 6.2
//
// クイズアプリの共通部分。アプリ側は QuizUI（と必要なら QuizCore）をリンクし、
// 問題データ・テーマ・文言だけを差し替えて別アプリにする。
//
// - QuizCore: モデル・問題データの読み込みと検証・出題ロジック・成績保存（Foundation のみ）
// - QuizUI:   画面・テーマ・広告の抽象化（SwiftUI）
// - quiz-tool: 問題 CSV を JSON に変換・検証する CLI（macOS 上でのみ使う）

import PackageDescription

let package = Package(
    name: "QuizKit",
    defaultLocalization: "ja",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "QuizCore", targets: ["QuizCore"]),
        .library(name: "QuizUI", targets: ["QuizUI"]),
        .executable(name: "quiz-tool", targets: ["QuizTool"]),
    ],
    targets: [
        .target(name: "QuizCore"),
        .target(
            name: "QuizUI",
            dependencies: ["QuizCore"]
        ),
        .executableTarget(
            name: "QuizTool",
            dependencies: ["QuizCore"]
        ),
        .testTarget(
            name: "QuizCoreTests",
            dependencies: ["QuizCore"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
