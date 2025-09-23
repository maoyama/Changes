//
//  GitRevParseTests.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2025/06/12.
//

import Testing
import Foundation
@testable import Changes

struct GitRevParseTests {

    @Test func gitPath() async throws {
        let gitRevParse = GitRevParse(directory: .testFixture!, gitPath: "MERGE_MSG")
        let path = try await Process.output(gitRevParse)
        #expect(path.hasSuffix("MERGE_MSG"))
    }

}
