//
//  QuizContentTests.swift
//  QuizTemplateAppTests
//
//  アプリに同梱した問題データ（Resources/quiz.json）がリリースできる状態かを確認する。
//  問題 CSV を差し替えたら、このテストが通ることを確認してからリリースする。
//

import Foundation
import QuizCore
@testable import QuizTemplateApp
import SwiftUI
import Testing

struct QuizContentTests {
    @Test
    func bundledQuizLoadsWithoutErrors() async throws {
        let pack = try await BundleQuizContentProvider(bundle: .main).loadPack()
        #expect(!pack.questions.isEmpty)
    }

    @Test
    func bundledQuizHasNoWarnings() async throws {
        let pack = try await BundleQuizContentProvider(bundle: .main).loadPack()
        let warnings = QuizPackValidator.validate(pack).warnings
        #expect(warnings.isEmpty, "\(warnings.map(\.description).joined(separator: "\n"))")
    }

    /// 問題で指定した画像が Asset Catalog に登録されているか
    @Test
    func referencedImagesExistInAssetCatalog() async throws {
        let pack = try await BundleQuizContentProvider(bundle: .main).loadPack()
        let missing = pack.questions
            .compactMap(\.imageName)
            .filter { UIImage(named: $0, in: .main, with: nil) == nil }
        #expect(missing.isEmpty, "Asset Catalog に無い画像: \(missing.joined(separator: ", "))")
    }
}
