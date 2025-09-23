//
//  MergeCommitContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/13.
//

import SwiftUI

struct MergeCommitContentView: View {
    var mergeCommit: Commit
    var directoryURL: URL
    @Binding var tab: Int
    @Binding var filesChanged: [ExpandableModel<FileDiff>]
    @State private var commits: [Commit] = []
    @State private var error: Error?

    var body: some View {
        DiffView(
            commits: $commits,
            filesChanged: $filesChanged,
            tab: $tab
        )
            .onChange(of: mergeCommit, initial: true) {
                Task {
                    do {
                        commits = try await Array(Process.output(GitLog(directory: directoryURL, revisionRange: ["\(mergeCommit.parentHashes[0])..\(mergeCommit.hash)"])).dropFirst())
                        let diffRaw = try await Process.output(
                            GitDiff(directory: directoryURL, noRenames: false, commitRange: mergeCommit.parentHashes[0] + ".." + mergeCommit.hash)
                        )
                        filesChanged = try Diff(raw: diffRaw).fileDiffs.map { .init(isExpanded: true, model: $0) }
                    } catch {
                        self.error = error
                    }
                }
            }
            .errorSheet($error)
    }
}

#Preview {
    ScrollView {
        MergeCommitContentView(
            mergeCommit: .init(
                hash: "11fff",
                parentHashes: ["21fff", "31fff"],
                author: "maoyama",
                authorEmail: "a@aoyama.dev",
                authorDate: "2014-10-10T13:50:40+09:00",
                title: "Hello world!",
                body: "body",
                branches: [],
                tags: []
            ),
            directoryURL: URL(string: "file:///maoyama/Projects/")!,
            tab: .constant(0),
            filesChanged: .constant([])
        )
    }
}
