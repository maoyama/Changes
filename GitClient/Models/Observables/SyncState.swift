//
//  SyncState.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/10.
//

import Foundation
import Observation

@MainActor
@Observable class SyncState {
    var folderURL: URL?
    var branch: Branch?
    var shouldPull = false
    var shouldPush = false

    func sync() async throws {
        guard let folderURL, let branch, !branch.isDetached else {
            shouldPull = false
            shouldPush = false
            return
        }
        try await GitFetchExecutor.shared.execute(GitFetch(directory: folderURL))

        let existRemoteBranch = try? await Process.output(GitShowref(directory: folderURL, pattern: "refs/remotes/origin/\(branch.name)"))
        guard existRemoteBranch != nil else {
            shouldPull = false
            shouldPush = true
            return
        }
        shouldPull = !(try await Process.output(GitLog(directory: folderURL, revisionRange: ["\(branch.name)..origin/\(branch.name)"])).isEmpty)
        shouldPush = !(try await Process.output(GitLog(directory: folderURL, revisionRange: ["origin/\(branch.name)..\(branch.name)"])).isEmpty)
    }
}
