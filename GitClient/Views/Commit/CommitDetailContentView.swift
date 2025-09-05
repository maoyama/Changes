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
    @State private var error: Error?

    var body: some View {
        ScrollView {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Text(commit.hash.prefix(10))
                        .textSelection(.disabled)
                        .help(commit.hash)
                        .contextMenu {
                            Button("Copy " + commit.hash) {
                                let pasteboard = NSPasteboard.general
                                pasteboard.declareTypes([.string], owner: nil)
                                pasteboard.setString(commit.hash, forType: .string)
                            }
                        }
                    Image(systemName: "arrow.left")
                    HStack(spacing: 0) {
                        ForEach(commit.parentHashes, id: \.self) { hash in
                            if hash == commit.parentHashes.first {
                                NavigationLink(commit.parentHashes[0].prefix(5), value: commit.parentHashes[0])
                                    .foregroundColor(.accentColor)
                            } else {
                                Text(",")
                                    .padding(.trailing, 2)
                                NavigationLink(commit.parentHashes[1].prefix(5), value: commit.parentHashes[1])
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .textSelection(.disabled)
                    if let mergedIn {
                        Divider()
                            .frame(height: 10)
                        HStack {
                            Image(systemName: "arrow.triangle.pull")
                            NavigationLink(mergedIn.hash.prefix(5), value: mergedIn.hash)
                                .foregroundColor(.accentColor)
                        }
                        .help("Merged in \(mergedIn.hash.prefix(5))")
                    }
                    if !commit.tags.isEmpty {
                        Divider()
                            .frame(height: 10)
                        HStack(spacing: 14) {
                            ForEach(commit.tags, id: \.self) { tag in
                                Label(tag, systemImage: "tag")
                            }
                        }
                    }
                    if !commit.branches.isEmpty {
                        Divider()
                            .frame(height: 10)
                        HStack(spacing: 14) {
                            ForEach(commit.branches, id: \.self) { branch in
                                Label(branch, systemImage: "arrow.triangle.branch")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .foregroundColor(.secondary)
                .buttonStyle(.link)
            }
            .padding(.top, 14)
            .padding(.horizontal)
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
                        MergeCommitContentView(mergeCommit: commit, directoryURL: folder.url)
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
            VStack(spacing: 0) {
                Spacer()
                HStack {
                    Text(shortstat)
                        .minimumScaleFactor(0.3)
                        .foregroundStyle(.primary)
                }
                .font(.callout)
                Spacer()
            }
            .frame(height: 40)
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
        .onChange(of: commit, initial: true, { _, commit in
            Task {
                shortstat = (try? await Process.output(GitShowShortstat(directory: folder.url, object: commit.hash))) ?? ""
            }
        })
        .errorSheet($error)
    }
}
