//
//  GitLogTests.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2024/10/01.
//

import Testing
import Foundation
@testable import Changes

struct GitLogTests {
    @Test func parse() async throws {
        try await Process.output(GitSwitch(directory: .testFixture!, branchName: "_test-fixture"))
        let gitlog = GitLog(directory: .testFixture!)
        let commits = try await Process.output(gitlog)
        #expect(commits.last!.hash == "f9635d9f3b39534e84f183555274867199af76a3")
        #expect(commits.last!.title == "Initial Commit")
        #expect(commits.last!.rawBody == "Initial Commit")
        #expect(commits.last!.body == "")
        #expect(commits.first!.parentHashes == ["cfae9305deac59f24365834d159bbc6fa57812b1", "e129fc78f4a907d6977af32985071d773cd6f4fa"])
        #expect(commits.first!.branches.contains("origin/main"))
        #expect(commits.first!.branches.contains("origin/HEAD"))
        #expect(commits.first!.tags == ["v0.2.0"])
        #expect(commits.first!.rawBody == """
Merge pull request #2 from maoyama/fix-typos

Fix typos
"""
        )
        #expect(commits.count == 29)
    }

    @Test func parseEmpty() async throws {
        let gitlog = GitLog(directory: URL(string: "file:///maoyama/Projects/")!)
        let output = ""
        let commits = try gitlog.parse(for: output)
        #expect(commits.count == 0)
    }
}
