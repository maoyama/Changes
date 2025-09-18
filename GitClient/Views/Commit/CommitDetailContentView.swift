//
//  CommitDetailContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/03/26.
//

import SwiftUI

struct CommitDetailContentView: View {
    var commit: Commit
    var folder: Folder
    @State private var commitDetail: CommitDetail?
    @State private var shortstat = ""
    @State private var fileDiffs: [ExpandableModel<FileDiff>] = []
    @State private var mergedIn: Commit?
    @State private var mergeCommitViewTab = 0
    @State private var mergeCommitFilesChanged: [ExpandableModel<FileDiff>] = []
    @State private var error: Error?

    var body: some View {
        ScrollView {
            CommitDetailHeaderView(commit: commit, mergedIn: $mergedIn)
            HStack {
                VStack (alignment: .leading, spacing: 0) {
                    Text(commit.title.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.title2)
                        .fontWeight(.bold)
                        .layoutPriority(1)
                        .padding(.top, 8)
                    if !commit.body.isEmpty {
                        Text(commit.body.trimmingCharacters(in: .whitespacesAndNewlines))
                            .font(.body)
                            .padding(.top, 4)
                    }
                    HStack {
                        Icon(size: .medium, authorEmail: commit.authorEmail, authorInitial: String(commit.author.initial.prefix(2)))
                        Text(commit.author)
                        Divider()
                            .frame(height: 10)
                        Text(commit.authorEmail)
                        Spacer()
                        Text(commit.authorDateDisplay)
                    }
                    .padding(.top)
                    .padding(.top, 2)
                    .foregroundStyle(.secondary)
                    Divider()
                        .padding(.top)
                    if commit.parentHashes.count == 2 {
                        MergeCommitContentView(
                            mergeCommit: commit,
                            directoryURL: folder.url,
                            tab: $mergeCommitViewTab,
                            filesChanged: $mergeCommitFilesChanged
                        )
                    } else {
                        FileDiffsView(expandableFileDiffs: $fileDiffs)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.textBackgroundColor))
        .textSelection(.enabled)
        .scrollEdgeEffectStyle(.soft, for: .bottom)
        .safeAreaBar(edge: .bottom, spacing: 0, content: {
            CommitDetailBottomBar(
                commit: commit,
                folder: folder,
                fileDiffs: bottomBarFileDiff()
            )
        })
        .onChange(of: commit, initial: true, { _, commit in
            Task {
                do {
                    commitDetail = try await Process.output(GitShow(directory: folder.url, object: commit.hash))
                    let mergeCommit = try await Process.output(GitLog(
                        directory: folder.url,
                        merges: true,
                        ancestryPath: true,
                        reverse: true,
                        revisionRange: ["\(commit.hash)..HEAD"]
                    )).first
                    if let mergeCommit {
                        let mergedInCommits = try await Process.output(GitLog(
                            directory: folder.url,
                            revisionRange: ["\(mergeCommit.parentHashes[0])..\(mergeCommit.hash)"]
                        ))
                        let contains = mergedInCommits.contains { $0.hash == commit.hash }
                        if contains  {
                            mergedIn = mergeCommit
                        } else {
                            mergedIn = nil
                        }
                    } else {
                        mergedIn = nil
                    }
                } catch {
                    commitDetail = nil
                    mergedIn = nil
                    self.error = error
                }
            }
        })
        .onChange(of: commitDetail, { _, newValue in
            if let newValue {
                fileDiffs = newValue.diff.fileDiffs.map { .init(isExpanded: true, model: $0) }
            } else {
                fileDiffs = []
            }
        })
        .errorSheet($error)
    }
    
    private func bottomBarFileDiff() -> Binding<[ExpandableModel<FileDiff>]> {
        if commit.parentHashes.count == 2 {
            return mergeCommitViewTab == 0 ? .constant([]) : $mergeCommitFilesChanged
        
        } else {
            return $fileDiffs
        }
    }
}
