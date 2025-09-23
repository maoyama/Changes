//
//  SyncStateTests.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2025/04/10.
//

import Testing
@testable import Changes
import Foundation

@MainActor
struct SyncStateTests {
    @Test func sync() async throws {
        let branchName = "_test-fixture"
        try await Process.output(GitSwitch(directory: .testFixture!, branchName: branchName))
        let state = SyncState()
        state.folderURL = .testFixture!
        state.branch = .init(name: branchName, isCurrent: true)
        try await state.sync()

        #expect(state.shouldPull == false)
        #expect(state.shouldPush == false)
    }

    @Test func newBranch() async throws {
        let branch = "_test-fixture-should-push-because-new-branch2"
        let _ = try? await Process.output(GitCheckoutB(directory: .testFixture!, newBranchName: branch, startPoint: "_test-fixture"))
        let state = SyncState()
        state.folderURL = .testFixture!
        state.branch = .init(name: branch, isCurrent: true)
        try await state.sync()

        #expect(state.shouldPull == false)
        #expect(state.shouldPush == true)
    }

    @Test func shouldPush() async throws {
        let branch = "_test-fixture-should-push"
        try await Process.output(GitSwitch(directory: .testFixture!, branchName: branch))
        try await Process.output(GitRevert(directory: .testFixture!, commit: "head"))
        let state = SyncState()
        state.folderURL = .testFixture!
        state.branch = .init(name: branch, isCurrent: true)
        try await state.sync()

        #expect(state.shouldPull == false)
        #expect(state.shouldPush == true)
    }

    @Test func shouldPull() async throws {
        let branch = "_test-fixture-should-pull"
        let _ = try? await Process.output(GitBranchDelete(directory: .testFixture!, branchName: branch))
        try await Process.output(GitCheckoutB(directory: .testFixture!, newBranchName: branch, startPoint: "_test-fixture"))
        let state = SyncState()
        state.folderURL = .testFixture!
        state.branch = .init(name: branch, isCurrent: true)
        try await state.sync()

        #expect(state.shouldPull == true)
        #expect(state.shouldPush == false)
    }

    @Test func syncDetached() async throws {
        let tag = "v0.2.0"
        try await Process.output(GitCheckout(directory: .testFixture!, commitHash: tag))
        let state = SyncState()
        state.folderURL = .testFixture!
        state.branch = try await Process.output(GitBranch(directory: .testFixture!)).current
        try await state.sync()

        #expect(state.shouldPull == false)
        #expect(state.shouldPush == false)
    }
}
