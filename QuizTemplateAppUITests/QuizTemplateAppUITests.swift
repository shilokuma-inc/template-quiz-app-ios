//
//  QuizTemplateAppUITests.swift
//  QuizTemplateAppUITests
//
//  Created by 村石 拓海 on 2024/05/12.
//

import XCTest

final class QuizTemplateAppUITests: XCTestCase {
    override func setUpWithError() throws {
        // UI テストでは失敗した時点で即座に止める
        continueAfterFailure = false
    }

    /// 学習記録・設定を保存しない状態で起動する（QuizRootView.uiTestingLaunchArgument）
    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-QuizUITesting"]
        app.launch()
        return app
    }

    @MainActor
    func testPlayQuizToResultAndBackHome() throws {
        let app = launchApp()

        let startButton = app.buttons["startQuizButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 10))
        startButton.tap()

        // 出題数は設定次第なので、結果画面が出るまで 1 番目の選択肢を選んで進める
        let resultScore = app.staticTexts["resultScore"]
        for _ in 0..<50 where !resultScore.exists {
            let choice = app.buttons["choice_0"]
            XCTAssertTrue(choice.waitForExistence(timeout: 5))
            choice.tap()
            XCTAssertTrue(app.staticTexts["answerFeedback"].waitForExistence(timeout: 5))
            app.buttons["nextButton"].tap()
            _ = resultScore.waitForExistence(timeout: 1)
        }
        XCTAssertTrue(resultScore.exists)

        app.buttons["backHomeButton"].tap()
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testOpenAndCloseSettings() throws {
        let app = launchApp()

        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10))
        settingsButton.tap()

        let closeButton = app.buttons["closeSettingsButton"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
        closeButton.tap()
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
    }
}
