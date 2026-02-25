//
//  SyncState.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/10.
//

import Foundation
import Observation
import os

@MainActor
@Observable class SyncState {
    private static let logger = Logger(subsystem: "dev.aoyama.changes", category: "SyncState")

    var folderURL: URL?
    var branch: Branch?
    var shouldPull = false
    var shouldPush = false
    var aheadCount: Int = 0
    var behindCount: Int = 0
    var syncError: String?

    func sync() async {
        guard let folderURL, let branch, !branch.isDetached else {
            shouldPull = false
            shouldPush = false
            aheadCount = 0
            behindCount = 0
            return
        }

        do {
            try await GitFetchExecutor.shared.execute(GitFetch(directory: folderURL))
            syncError = nil
        } catch {
            Self.logger.warning("git fetch failed: \(error.localizedDescription)")
            syncError = error.localizedDescription
            shouldPull = false
            shouldPush = false
            aheadCount = 0
            behindCount = 0
            return
        }

        do {
            let existRemoteBranch = try? await Process.output(GitShowref(directory: folderURL, pattern: "refs/remotes/origin/\(branch.name)"))
            guard existRemoteBranch != nil else {
                shouldPull = false
                shouldPush = true
                aheadCount = try await Process.output(GitRevListCount(directory: folderURL)) ?? 0
                behindCount = 0
                return
            }
            shouldPull = !(try await Process.output(GitLog(directory: folderURL, revisionRange: ["\(branch.name)..origin/\(branch.name)"])).isEmpty)
            shouldPush = !(try await Process.output(GitLog(directory: folderURL, revisionRange: ["origin/\(branch.name)..\(branch.name)"])).isEmpty)
            aheadCount = try await Process.output(GitRevListCount(directory: folderURL, commit: "origin/\(branch.name)..\(branch.name)")) ?? 0
            behindCount = try await Process.output(GitRevListCount(directory: folderURL, commit: "\(branch.name)..origin/\(branch.name)")) ?? 0
        } catch {
            Self.logger.warning("git log for sync check failed: \(error.localizedDescription)")
            shouldPull = false
            shouldPush = false
            aheadCount = 0
            behindCount = 0
        }
    }
}
