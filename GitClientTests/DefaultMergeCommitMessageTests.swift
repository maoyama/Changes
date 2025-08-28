//
//  DefaultMergeCommitMessageTests.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2025/06/14.
//

import Testing
@testable import Changes
import Foundation

struct DefaultMergeCommitMessageTests {

    @Test func get() async throws {
        try await Process.output(GitSwitch(directory: .testFixture!, branchName: "_test-fixture-conflict"))
        try await Process.output(GitSwitch(directory: .testFixture!, branchName: "_test-fixture-conflict2"))
        do {
            try await Process.output(GitMerge(directory: .testFixture!, branchName: "_test-fixture-conflict"))
        } catch {
            // A conflict error occurred
            print(error)
        }
        let string = try await DefaultMergeCommitMessage(directory: .testFixture!).get()
        let expectedString = """
Merge branch '_test-fixture-conflict' into _test-fixture-conflict2

# Conflicts:
#\tExamples/Examples/ContentView.swift
#\tREADME.md
"""

        #expect(string == expectedString)

        //　Cleanup
        try await Process.output(GitAdd(directory: .testFixture!))
        try await Process.output(GitStash(directory: .testFixture!))
    }

}
