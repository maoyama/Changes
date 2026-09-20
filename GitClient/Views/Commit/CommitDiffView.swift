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
    var showsComparisonControls = true

    @State private var commitFirst = ""
    @State private var commitSecond = ""
    @State private var filesChanges: [ExpandableModel<FileDiff>] = []
    @State private var filesChangesIsEmpty = false
    @State private var shortstat = ""
    @State private var error: Error?

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
        .scrollEdgeEffectStyle(.soft, for: .vertical)
        .safeAreaBar(edge: .bottom, spacing: 0, content: {
            VStack(spacing: 0) {
                DiffSummaryView(fileDiffs: filesChanges)
                HStack(spacing: 0) {
                    if showsComparisonControls {
                        HStack {
                            Text("Diff")
                                .foregroundStyle(.secondary)
                            Text(title(for: commitFirst))
                                .lineLimit(1)
                                .help(title(for: commitFirst))
                            Image(systemName: "arrow.right")
                                .foregroundStyle(.secondary)
                            Text(title(for: commitSecond))
                                .lineLimit(1)
                                .help(title(for: commitSecond))
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
                            .frame(height: 16)
                    }
                    HStack {
                        Button {
                            filesChanges = filesChanges.map {
                                ExpandableModel(isExpanded: true, model: $0.model)
                            }
                        } label: {
                            Image(systemName: "arrow.up.and.line.horizontal.and.arrow.down")
                        }
                        .help("Expand All Files")
                        Button {
                            filesChanges = filesChanges.map {
                                ExpandableModel(isExpanded: false, model: $0.model)
                            }
                        } label: {
                            Image(systemName: "arrow.down.and.line.horizontal.and.arrow.up")
                        }
                        .help("Collapse All Files")
                    }
                    .padding(.leading)
                    .buttonStyle(.plain)
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
        .onChange(of: [selectionLogID, subSelectionLogID], initial: true) { oldValue, newValue in
            commitFirst = selectionLogID
            commitSecond = subSelectionLogID
        }
        .task(id: [commitFirst, commitSecond]) {
            guard !commitFirst.isEmpty, !commitSecond.isEmpty else { return }
            if commitFirst == Log.notCommitted.id {
                await updateDiff(commitRange: commitSecond)
            } else if commitSecond == Log.notCommitted.id {
                await updateDiff(commitRange: commitFirst)
            } else {
                await updateDiff(commitRange: commitFirst + ".." + commitSecond)
            }
        }
        .errorSheet($error)
    }

    private func title(for revision: String) -> String {
        return revision == Log.notCommitted.id ? "Staged Changes" : String(revision.prefix(5))
    }

    private func updateDiff(commitRange: String) async {
        guard let folder else { return }
        filesChanges = []
        filesChangesIsEmpty = false
        shortstat = ""
        do {
            let raw = try await Process.output(
                GitDiff(directory: folder, noRenames: false, commitRange: commitRange)
            )
            let changes = try Diff(raw: raw).fileDiffs.map { ExpandableModel(isExpanded: true, model: $0) }
            let stat = try await Process.output(
                GitDiff(directory: folder, noRenames: false, shortstat: true, commitRange: commitRange)
            ).trimmingCharacters(in: .whitespacesAndNewlines)
            try Task.checkCancellation()
            filesChanges = changes
            filesChangesIsEmpty = changes.isEmpty
            shortstat = stat.isEmpty ? "No Changes" : stat
        } catch {
            guard !Task.isCancelled else { return }
            self.error = error
        }
    }
}
