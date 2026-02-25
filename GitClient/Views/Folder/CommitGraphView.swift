//
//  CommitGraphView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/11.
//

import SwiftUI

struct CommitGraphView: View {
    @Binding var logStore: LogStore
    @Binding var selectionLogID: String?
    @Binding var subSelectionLogID: String?
    @Binding var showing: FolderViewShowing
    @Binding var isRefresh: Bool
    @State private var isLoading = false

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            CommitGraphContentView(
                notCommitted: $logStore.notCommitted,
                selectionLogID: $selectionLogID,
                subSelectionLogID: $subSelectionLogID,
                logStore: $logStore,
                showing: $showing,
                isRefresh: $isRefresh,
                commits: CommitGraph().positionedCommits(logStore.commits)
            )
            .padding(.horizontal)
            .padding(.top, logStore.notCommitted?.isEmpty == true ? 22 : 14)
            .padding(.bottom, 22)
            if logStore.canLoadMore {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else {
                        Button("More") {
                            Task {
                                isLoading = true
                                await logStore.loadMore()
                                isLoading = false
                            }
                        }
                        .buttonStyle(.link)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.horizontal, 8)
                .padding(.bottom, 22)
            }
        }
        .background(Color(NSColor.textBackgroundColor))
        .focusable()
        .focusEffectDisabled()
        .onMoveCommand { direction in
            guard let selectionLogID else { return }
            switch direction {
            case .down:
                if let next = logStore.nextLogID(logID: selectionLogID) {
                    self.selectionLogID = next
                }
            case .up:
                if let previous = logStore.previousLogID(logID: selectionLogID) {
                    self.selectionLogID = previous
                }
            case .left, .right:
                break
            @unknown default:
                break
            }
        }
    }
}

struct CommitGraphContentView: View {
    @Environment(\.folder) private var folder
    @Binding var notCommitted: NotCommitted?
    @Binding var selectionLogID: String?
    @Binding var subSelectionLogID: String?
    @Binding var logStore: LogStore
    @Binding var showing: FolderViewShowing
    @Binding var isRefresh: Bool
    @State private var error: Error?
    var commits: [PositionedCommit]
    let xSpacing: CGFloat = 26
    let ySpacing: CGFloat = 42
    let textWidth: CGFloat = 180
    let textHeight: CGFloat = 38

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let notCommitted, !notCommitted.isEmpty {
                HStack (spacing: selectionLogID == Log.notCommitted.id ? 5 : 7) {
                    GraphNode(
                        logID: Log.notCommitted.id,
                        selectionLogID: $selectionLogID,
                        subSelectionLogID: $subSelectionLogID
                    )
                    .tapGesture(logID: Log.notCommitted.id, selectionLogID: $selectionLogID, subSelectionLogID: $subSelectionLogID)

                    GraphNodeText(logID: Log.notCommitted.id, title: "Uncommitted Changes", selectionLogID: $selectionLogID, subSelectionLogID: $subSelectionLogID)
                        .tapGesture(logID: Log.notCommitted.id, selectionLogID: $selectionLogID, subSelectionLogID: $subSelectionLogID)

                }
                .padding(
                    .horizontal,
                    selectionLogID == Log.notCommitted.id ? -2 : 0
                )
                .padding(.top, -4)
                .padding(.bottom, 24)
            }

            ZStack(alignment:.leading) {
                // 線（親子関係）を描く
                ForEach(commits) { commit in
                    if let from = position(of: commit) {
                        ForEach(commit.commit.parentHashes, id: \.self) { parentHash in
                            if let parent = commits.first(where: { $0.commit.hash == parentHash }), !parent.childrenIsHidden , let to = position(of: parent) {
                                Path { path in
                                    path.move(to: from)
                                    path.addLine(to: to)
                                }
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 6)
                            }
                        }
                    }
                }

                // ノードを描く
                ForEach(commits) { commit in
                    if let point = position(of: commit), let folder {
                        GraphNode(
                            logID: commit.id,
                            selectionLogID: $selectionLogID,
                            subSelectionLogID: $subSelectionLogID
                        )
                            .position(point)
                            .commitContextMenu(
                                folder: folder,
                                commit: commit.commit,
                                logStore: logStore,
                                isRefresh: $isRefresh,
                                showing: $showing,
                                bindingError: $error
                            )
                            .tapGesture(logID: commit.id, selectionLogID: $selectionLogID, subSelectionLogID: $subSelectionLogID)
                        GraphNodeText(
                            logID: commit.id,
                            title: commit.commit.title,
                            selectionLogID: $selectionLogID,
                            subSelectionLogID: $subSelectionLogID
                        )
                            .frame(width: textWidth, height: textHeight, alignment: .leading)
                            .offset(.init(width: textWidth / 2 + 14, height: 0))
                            .position(point)
                            .commitContextMenu(
                                folder: folder,
                                commit: commit.commit,
                                logStore: logStore,
                                isRefresh: $isRefresh,
                                showing: $showing,
                                bindingError: $error
                            )
                            .tapGesture(logID: commit.id, selectionLogID: $selectionLogID, subSelectionLogID: $subSelectionLogID)
                    }
                }
            }
            .frame(
                width: CGFloat((commits.map { $0.column }.max() ?? 0)) * xSpacing + textWidth + 14,
                height: CGFloat(commits.count - 1) * ySpacing + GraphNode.nodeSize
            )
            .errorSheet($error)
        }
    }

    private func position(of commit: PositionedCommit) -> CGPoint? {
        var p = CGPoint(
            x: CGFloat(commit.column) * xSpacing + GraphNode.nodeSize / 2,
            y: CGFloat(commit.row) * ySpacing + GraphNode.nodeSize / 2
        )
        if commit.childrenIsHidden {
            p.x += 0.5 * xSpacing
        }
        return p
    }
}

struct GraphNode: View {
    static let nodeSize: CGFloat = 14
    static let selectedNodeSize: CGFloat = 18
    var logID: String
    @Binding var selectionLogID: String?
    @Binding var subSelectionLogID: String?
    @Environment(\.isFocused) private var isFocused
    @Environment(\.appearsActive) private var appearsActive
    private var active:Bool { isFocused && appearsActive }

    private var fillColor: Color {
        if logID == selectionLogID || logID == subSelectionLogID {
            return active ? Color(NSColor.selectedContentBackgroundColor) : Color(NSColor.unemphasizedSelectedContentBackgroundColor)
        }
        if logID == Log.notCommitted.id {
            return Color.secondary
        }
        return Color.primary
    }

    var body: some View {
        Circle()
            .fill(fillColor)
            .overlay(
                Circle()
                    .stroke(Color(NSColor.textBackgroundColor), lineWidth: 2)
            )
            .frame(
                width: logID == selectionLogID || logID == subSelectionLogID ? Self.selectedNodeSize: Self.nodeSize,
                height: logID == selectionLogID || logID == subSelectionLogID ? Self.selectedNodeSize: Self.nodeSize
            )
    }
}

struct GraphNodeText: View {
    var logID: String
    var title: String
    var foregroundStyle: Color {
        guard active else {
            return logID == selectionLogID || logID == subSelectionLogID ? Color(NSColor.unemphasizedSelectedTextColor) : .secondary
        }
        return logID == selectionLogID || logID == subSelectionLogID ? .white : .secondary
    }

    @Binding var selectionLogID: String?
    @Binding var subSelectionLogID: String?
    @Environment(\.isFocused) private var isFocused
    @Environment(\.appearsActive) private var appearsActive
    private var active:Bool { isFocused && appearsActive }

    var body: some View {
        VStack {
            Text(title)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
        }
            .font(.callout)
            .foregroundStyle(foregroundStyle)
            .background {
                if logID == selectionLogID || logID == subSelectionLogID {
                    RoundedRectangle(cornerRadius: 4)
                        .fill( active ? Color(NSColor.selectedContentBackgroundColor) : Color(NSColor.unemphasizedSelectedContentBackgroundColor))
                }
            }
    }
}

#Preview {
    @Previewable @State var selectionLogID: String?
    @Previewable @State var subSelectionLogID: String?
    @Previewable @State var logStore = LogStore()
    @Previewable @State var showing = FolderViewShowing()
    @Previewable @State var isRefresh = false

    let sampleCommits = [
        Commit(hash: "d", treeHash: "", parentHashes: ["b", "c"], author: "Dave", authorEmail: "", authorDate: "2023-10-04T12:00:00Z", title: "Merge feature", body: "", branches: [], tags: []),
        Commit(hash: "c", treeHash: "", parentHashes: ["b"], author: "Carol", authorEmail: "", authorDate: "2023-10-03T12:00:00Z", title: "Fix bug Fix bug Fix bug Fix bug Fix bug Fix bug Fix bug Fix bug Fix bug", body: "", branches: [], tags: []),
        Commit(hash: "b", treeHash: "", parentHashes: ["a"], author: "Bob", authorEmail: "", authorDate: "2023-10-02T12:00:00Z", title: "Add feature", body: "", branches: [], tags: []),
        Commit(hash: "a", treeHash: "", parentHashes: [], author: "Alice", authorEmail: "", authorDate: "2023-10-01T12:00:00Z", title: "Initial commit", body: "", branches: [], tags: [])
    ]

    CommitGraphContentView(
        notCommitted: .constant(NotCommitted(diff: "hi", diffCached: "hello", status: .init(untrackedFiles: [], unmergedFiles: []))),
        selectionLogID: $selectionLogID,
        subSelectionLogID: $subSelectionLogID,
        logStore: $logStore,
        showing: $showing,
        isRefresh: $isRefresh,
        commits: CommitGraph().positionedCommits(sampleCommits)
    )
    .environment(\.folder, URL(string: "file:///Users/aoyama/Projects/GitClient/"))
        .background(Color(NSColor.textBackgroundColor))
        .frame(width: 400, height: 600)
}

#Preview {
    @Previewable @State var selectionLogID: String?
    @Previewable @State var subSelectionLogID: String?
    @Previewable @State var logStore = LogStore()
    @Previewable @State var showing = FolderViewShowing()
    @Previewable @State var isRefresh = false

    let sampleCommits2 = [
        Commit(hash: "f", treeHash: "", parentHashes: ["d", "e"], author: "Frank", authorEmail: "", authorDate: "2023-10-06T12:00:00Z", title: "Merge bugfix", body: "", branches: [], tags: []),
        Commit(hash: "e", treeHash: "", parentHashes: ["c"], author: "Eve", authorEmail: "", authorDate: "2023-10-05T12:00:00Z", title: "Bugfix", body: "", branches: [], tags: []),
        Commit(hash: "d", treeHash: "", parentHashes: ["b", "c"], author: "Dave", authorEmail: "", authorDate: "2023-10-04T12:00:00Z", title: "Merge feature", body: "", branches: [], tags: []),
        Commit(hash: "c", treeHash: "", parentHashes: ["b"], author: "Carol", authorEmail: "", authorDate: "2023-10-03T12:00:00Z", title: "Fix bug", body: "", branches: [], tags: []),
        Commit(hash: "b", treeHash: "", parentHashes: ["a"], author: "Bob", authorEmail: "", authorDate: "2023-10-02T12:00:00Z", title: "Add feature", body: "", branches: [], tags: []),
        Commit(hash: "a", treeHash: "", parentHashes: [], author: "Alice", authorEmail: "", authorDate: "2023-10-01T12:00:00Z", title: "Initial commit", body: "", branches: [], tags: [])
    ]

    CommitGraphContentView(
        notCommitted: .constant(NotCommitted(diff: "", diffCached: "", status: .init(untrackedFiles: [], unmergedFiles: []))),
        selectionLogID: $selectionLogID,
        subSelectionLogID: $subSelectionLogID,
        logStore: $logStore,
        showing: $showing,
        isRefresh: $isRefresh,
        commits: CommitGraph().positionedCommits(sampleCommits2)
    )
    .environment(\.folder, URL(string: "file:///Users/aoyama/Projects/GitClient/"))
        .background(Color(NSColor.textBackgroundColor))
        .frame(width: 400, height: 600)
}

#Preview("In Search") {
    @Previewable @State var selectionLogID: String?
    @Previewable @State var subSelectionLogID: String?
    @Previewable @State var logStore = LogStore()
    @Previewable @State var showing = FolderViewShowing()
    @Previewable @State var isRefresh = false

    let sampleCommitsInSearch = [
        Commit(hash: "f", treeHash: "", parentHashes: ["d", "e"], author: "Frank", authorEmail: "", authorDate: "2023-10-06T12:00:00Z", title: "Merge bugfix", body: "", branches: [], tags: []),
        Commit(hash: "e", treeHash: "", parentHashes: ["c"], author: "Eve", authorEmail: "", authorDate: "2023-10-05T12:00:00Z", title: "Bugfix", body: "", branches: [], tags: []),
        Commit(hash: "d", treeHash: "", parentHashes: ["b", "c"], author: "Dave", authorEmail: "", authorDate: "2023-10-04T12:00:00Z", title: "Merge feature", body: "", branches: [], tags: []),
        Commit(hash: "x", treeHash: "", parentHashes: ["b"], author: "Carol", authorEmail: "", authorDate: "2023-10-03T12:00:00Z", title: "Fix bug", body: "", branches: [], tags: []),
        Commit(hash: "b", treeHash: "", parentHashes: ["a"], author: "Bob", authorEmail: "", authorDate: "2023-10-02T12:00:00Z", title: "Add feature", body: "", branches: [], tags: []),
        Commit(hash: "a'", treeHash: "", parentHashes: [], author: "Alice", authorEmail: "", authorDate: "2023-10-01T12:00:00Z", title: "Initial commit", body: "", branches: [], tags: [])
    ]

    CommitGraphContentView(
        notCommitted: .constant(NotCommitted(diff: "", diffCached: "", status: .init(untrackedFiles: [], unmergedFiles: []))),
        selectionLogID: $selectionLogID,
        subSelectionLogID: $subSelectionLogID,
        logStore: $logStore,
        showing: $showing,
        isRefresh: $isRefresh,
        commits: CommitGraph().positionedCommits(sampleCommitsInSearch)
    )
    .environment(\.folder, URL(string: "file:///Users/aoyama/Projects/GitClient/"))
        .background(Color(NSColor.textBackgroundColor))
        .frame(width: 400, height: 600)
}

