//
//  CommitDetailHeaderView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/09/18.
//

import SwiftUI

struct CommitDetailHeaderView: View {
    var commit: Commit
    var fileDiffs: [FileDiff]
    @Binding var mergedIn: Commit?

    private var totalInsertions: Int {
        fileDiffs.reduce(0) { $0 + $1.insertions }
    }

    private var totalDeletions: Int {
        fileDiffs.reduce(0) { $0 + $1.deletions }
    }

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
            // Commit Hash
            GridRow {
                Text("Commit")
                    .gridColumnAlignment(.trailing)
                    .foregroundStyle(.secondary)
                Text(commit.hash)
                    .fontDesign(.monospaced)
                    .textSelection(.enabled)
                    .contextMenu {
                        Button("Copy Commit Hash") {
                            let pasteboard = NSPasteboard.general
                            pasteboard.declareTypes([.string], owner: nil)
                            pasteboard.setString(commit.hash, forType: .string)
                        }
                    }
            }

            // Tree
            GridRow {
                Text("Tree")
                    .foregroundStyle(.secondary)
                Text(commit.treeHash)
                    .fontDesign(.monospaced)
                    .textSelection(.enabled)
            }

            // Author
            GridRow {
                Text("Author")
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Icon(size: .medium, authorEmail: commit.authorEmail, authorInitial: String(commit.author.initial.prefix(2)))
                    Text("\(commit.author) <\(commit.authorEmail)>")
                }
                .gridCellUnsizedAxes(.horizontal)
            }

            // Date
            GridRow {
                Text("Date")
                    .foregroundStyle(.secondary)
                Text(commit.authorDateMedium)
            }

            // Parent(s)
            GridRow {
                Text(commit.parentHashes.count > 1 ? "Parents" : "Parent")
                    .foregroundStyle(.secondary)
                HStack(spacing: 0) {
                    ForEach(Array(commit.parentHashes.enumerated()), id: \.element) { index, hash in
                        if index > 0 {
                            Text(", ")
                        }
                        NavigationLink(hash, value: hash)
                            .foregroundColor(.accentColor)
                            .fontDesign(.monospaced)
                    }
                }
                .textSelection(.disabled)
                .gridCellUnsizedAxes(.horizontal)
            }

            // Stats
            if !fileDiffs.isEmpty {
                GridRow {
                    Text("Stats")
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Text("\(fileDiffs.count) file\(fileDiffs.count == 1 ? "" : "s") changed")
                        if totalDeletions > 0 {
                            DiffStatBadge(text: "-\(totalDeletions)", color: .red)
                        }
                        if totalInsertions > 0 {
                            DiffStatBadge(text: "+\(totalInsertions)", color: .green)
                        }
                    }
                }
            }

            // Merged In
            if let mergedIn {
                GridRow {
                    Text("Merged in")
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.pull")
                            .foregroundStyle(.secondary)
                        NavigationLink(mergedIn.hash.prefix(7), value: mergedIn.hash)
                            .foregroundColor(.accentColor)
                            .fontDesign(.monospaced)
                    }
                    .textSelection(.disabled)
                }
            }

            // Tags
            if !commit.tags.isEmpty {
                GridRow {
                    Text(commit.tags.count > 1 ? "Tags" : "Tag")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(commit.tags, id: \.self) { tag in
                            Label(tag, systemImage: "tag")
                        }
                    }
                    .gridCellUnsizedAxes(.horizontal)
                }
            }

            // Branches
            if !commit.branches.isEmpty {
                GridRow {
                    Text(commit.branches.count > 1 ? "Branches" : "Branch")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(commit.branches, id: \.self) { branch in
                            Label(branch, systemImage: "arrow.triangle.branch")
                                .foregroundColor(.secondary)
                        }
                    }
                    .gridCellUnsizedAxes(.horizontal)
                }
            }
        }
        .buttonStyle(.link)
    }
}
