//
//  CommitDiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/05/15.
//

import SwiftUI

struct CommitDiffView: View {
    @Environment(\.folder) private var folder
    var selectionLogID: String
    var subSelectionLogID: String

    @State private var commitFirst = ""
    @State private var commitSecond = ""
    @State private var filesChanges: [ExpandableModel<FileDiff>] = []
    @State private var filesChangesIsEmpty = false
    @State private var shortstat = ""
    @State private var error: Error?
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollView {
            if filesChangesIsEmpty {
                LazyVStack(alignment: .center) {
                    Label("No Changes", systemImage: "plusminus")
                        .foregroundStyle(.secondary)
                        .padding()
                        .padding()
                        .padding(.vertical, 40)
                }
            }
            FileDiffsView(expandableFileDiffs: $filesChanges)
                .padding(.horizontal)
        }
        .background(Color(NSColor.textBackgroundColor))
        .scrollEdgeEffectStyle(.soft, for: .bottom)
        .safeAreaBar(edge: .bottom, spacing: 0, content: {
            VStack(spacing: 0) {
                DiffSummaryView(fileDiffs: filesChanges)
                HStack(spacing: 0) {
                    HStack {
                        Text("Diff")
                            .foregroundStyle(.secondary)
                        Text(commitFirst == Log.notCommitted.id ? "Staged Changes" : commitFirst.prefix(5))
                        Text(commitSecond == Log.notCommitted.id ? "Staged Changes" : commitSecond.prefix(5))
                        Button {
                            let first = commitFirst
                            let second = commitSecond
                            commitFirst = second
                            commitSecond = first
                        } label: {
                            Image(systemName: "arrow.left.arrow.right")
                        }
                            .buttonStyle(.plain)
                            .help("Swap the Commits")
                    }
                    .padding(.horizontal)
                    Divider()
                    Spacer()
                    Text(shortstat)
                        .minimumScaleFactor(0.3)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .font(.callout)
                .frame(height: 40)
            }
        })
        .onChange(of: selectionLogID + subSelectionLogID, initial: true) { oldValue, newValue in
            commitFirst = selectionLogID
            commitSecond = subSelectionLogID
        }
        .onChange(of: commitFirst + commitSecond, initial: true) { _, _ in
            if commitFirst == Log.notCommitted.id {
                updateDiff(commitRange: commitSecond)
            } else if commitSecond == Log.notCommitted.id {
                updateDiff(commitRange: commitFirst)
            } else {
                updateDiff(commitRange: commitFirst + ".." + commitSecond)
            }
        }
        .errorSheet($error)
    }

    private func updateDiff(commitRange: String) {
        guard let folder else { return }
        Task {
            do {
                let raw = try await Process.output(
                    GitDiff(directory: folder, noRenames: false, commitRange: commitRange)
                )
                filesChanges = try Diff(raw: raw).fileDiffs.map { .init(isExpanded: true, model: $0) }
                filesChangesIsEmpty = filesChanges.isEmpty
                shortstat = try await Process.output(
                    GitDiff(directory: folder, noRenames: false, shortstat: true, commitRange: commitRange)
                ).trimmingCharacters(in: .whitespacesAndNewlines)
                if shortstat.isEmpty {
                    shortstat = "No Changes"
                }
            } catch {
                self.error = error
            }
        }
    }
}
