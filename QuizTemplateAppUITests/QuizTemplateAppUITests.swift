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

    /// ホームから始めて 1 問答えると、2 問目に進む
    @MainActor
    func testStartAndAnswerFirstQuestion() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let start = app.buttons["start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()

        XCTAssertTrue(app.staticTexts["1 / 10"].waitForExistence(timeout: 5))
        // 選択肢は「What is the capital of …?」の問題文の下に並ぶボタン。戻るボタン以外の最初のボタンを押す
        let choice = app.buttons.matching(NSPredicate(format: "label != %@", "Back")).element(boundBy: 1)
        XCTAssertTrue(choice.waitForExistence(timeout: 5))
        choice.tap()

        XCTAssertTrue(app.staticTexts["2 / 10"].waitForExistence(timeout: 5))
    }
}
