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
    var syncError: String?

    func sync() async {
        guard let folderURL, let branch, !branch.isDetached else {
            shouldPull = false
            shouldPush = false
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
            return
        }

        do {
            let existRemoteBranch = try? await Process.output(GitShowref(directory: folderURL, pattern: "refs/remotes/origin/\(branch.name)"))
            guard existRemoteBranch != nil else {
                shouldPull = false
                shouldPush = true
                return
            }
            shouldPull = !(try await Process.output(GitLog(directory: folderURL, revisionRange: ["\(branch.name)..origin/\(branch.name)"])).isEmpty)
            shouldPush = !(try await Process.output(GitLog(directory: folderURL, revisionRange: ["origin/\(branch.name)..\(branch.name)"])).isEmpty)
        } catch {
            Self.logger.warning("git log for sync check failed: \(error.localizedDescription)")
            shouldPull = false
            shouldPush = false
        }
    }
}
