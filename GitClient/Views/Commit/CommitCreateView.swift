//
//  CommitView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/01.
//

import SwiftUI
import os

struct CommitCreateView: View {
    @Environment(\.openSettings) var openSettings: OpenSettingsAction
    @Environment(\.appearsActive) private var appearsActive

    var folder: Folder
    @State private var cachedDiffShortStat = ""
    @State private var diffShortStat = ""
    private var stagedHeaderCaption: String {
        if cachedDiffShortStat.isEmpty {
            return " No Changes"
        } else {
            return cachedDiffShortStat
        }
    }
    private var notStagedHeaderCaption: String {
        if let untrackedStat = status?.untrackedFilesShortStat, !untrackedStat.isEmpty {
            if diffShortStat.isEmpty {
                return " " + untrackedStat
            } else {
                return diffShortStat + ", " + untrackedStat
            }
        }
        if diffShortStat.isEmpty {
            return " No Changes"
        } else {
            return diffShortStat
        }
    }
    private var canStage: Bool {
        if !diffRaw.isEmpty {
            return true
        }
        if let untrackedFiles = status?.untrackedFiles {
            if !untrackedFiles.isEmpty {
                return true
            }
        }

        return false
    }
    @State private var cachedDiffRaw = ""
    @State private var diffRaw = ""
    @State private var cachedDiff: Diff?
    @State private var cachedExpandableFileDiffs: [ExpandableModel<FileDiff>] = []
    @State private var diff: Diff?
    @State private var expandableFileDiffs: [ExpandableModel<FileDiff>] = []
    @State private var status: Status?
    @State private var cachedDiffStat: DiffStat?
    @State private var updateChangesError: Error?
    @State private var commitMessage = ""
    @State private var suggestedCommitMessage = ""
    @State private var error: Error?
    @State private var isAmend = false
    @State private var amendCommit: Commit?
    @State private var isStagingChanges = false
    @State private var isGeneratingCommitMessage = false
    @Binding var isRefresh: Bool
    var onCommit: () -> Void
    var onStash: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if cachedDiff != nil {
                    StagedView(
                        fileDiffs: $cachedExpandableFileDiffs,
                        onSelectFileDiff: { fileDiff in
                            if let newDiff = self.cachedDiff?.updateFileDiffStage(fileDiff, stage: false) {
                                restorePatch(newDiff)
                            }
                        },
                        onSelectChunk: status?.unmergedFiles.isEmpty == false ? nil : { fileDiff, chunk in
                            if let newDiff = self.cachedDiff?.updateChunkStage(chunk, in: fileDiff, stage: false) {
                                restorePatch(newDiff)
                            }
                        }
                    )
                    .padding(.top)
                }

                if diff != nil {
                    UnstagedView(
                        fileDiffs: $expandableFileDiffs,
                        untrackedFiles: status?.untrackedFiles ?? [],
                        onSelectFileDiff: { fileDiff in
                            if let newDiff = self.diff?.updateFileDiffStage(fileDiff, stage: true) {
                                addPatch(newDiff)
                            }
                        },
                        onSelectChunk: status?.unmergedFiles.isEmpty == false ? nil : { fileDiff, chunk in
                            if let newDiff = self.diff?.updateChunkStage(chunk, in: fileDiff, stage: true) {
                                addPatch(newDiff)
                            }
                        },
                        onSelectUntrackedFile: { file in
                            Task {
                                do {
                                    try await Process.output(GitAddPathspec(directory: folder.url, pathspec: file))
                                    await updateChanges()
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                    )
                    .padding(.bottom)
                }

                if let updateChangesError {
                    Label(updateChangesError.localizedDescription, systemImage: "exclamationmark.octagon")
                    Text(cachedDiffRaw + diffRaw)
                        .padding()
                        .font(Font.system(.body, design: .monospaced))
                }
            }
            .safeAreaInset(edge: .top, spacing: 0, content: {
                VStack(spacing: 0) {
                    HStack {
                        Button {
                            Task {
                                do {
                                    try await Process.output(GitStash(directory: folder.url))
                                    onStash()
                                } catch {
                                    self.error = error
                                }
                            }
                        } label: {
                            Image(systemName: "tray.and.arrow.down")
                        }
                        .help("Stash Include Untracked")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                HStack(spacing: 6) {
                                    Text("Staged ").foregroundStyle(.secondary)
                                    Text(stagedHeaderCaption)
                                }
                                HStack(spacing: 6) {
                                    Text("Unstaged ").foregroundStyle(.secondary)
                                    Text(notStagedHeaderCaption)
                                }
                            }
                            .font(.callout)
                        }
                        .padding(.horizontal)
                        Button("Stage All") {
                            Task {
                                do {
                                    try await Process.output(GitAdd(directory: folder.url))
                                    await updateChanges()
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                        .disabled(!canStage)
                        .layoutPriority(2)

                        Button("Unstage All") {
                            Task {
                                do {
                                    try await Process.output(GitRestore(directory: folder.url))
                                    await updateChanges()
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                        .disabled(cachedDiffRaw.isEmpty)
                        .padding(.leading, 7)
                        .layoutPriority(2)
                    }
                    .textSelection(.disabled)
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    Divider()
                }
                .background(Color(nsColor: .textBackgroundColor))
            })
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            .background(Color(NSColor.textBackgroundColor))
            Divider()
            HStack(alignment: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    ZStack {
                            TextEditor(text: $commitMessage)
                                .padding(.top, 16)
                                .padding(.horizontal, 12)
                            if commitMessage.isEmpty {
                                Label("Enter commit message here", systemImage: "plus.bubble")
                                    .foregroundColor(.secondary)
                                    .allowsHitTesting(false)
                            }
                    }
                    .overlay(alignment: .bottom) {
                        if !suggestedCommitMessage.isEmpty {
                            GeneratedCommitMessageView(
                                commitMessage: $commitMessage,
                                suggestedCommitMessage: $suggestedCommitMessage
                            ) {
                                Task {
                                    await generateCommitMessage()
                                }
                            }
                                .padding(.horizontal)
                        }
                    }
                    HStack(spacing: 0) {
                        CommitMessageSuggestionView()
                        Button {
                            Task {
                                isGeneratingCommitMessage = true
                                do {
                                    commitMessage = try await SystemLanguageModelService().commitMessage(stagedDiff: cachedDiffRaw)
                                } catch {
                                    self.error = error
                                }
                                isGeneratingCommitMessage = false
                            }
                        } label: {
                            if isGeneratingCommitMessage {
                                ProgressView()
                                    .scaleEffect(x: 0.4, y: 0.4, anchor: .center)
                                    .frame(width: 15, height: 10)
                            } else {
                                Image(systemName: "sparkle")
                                    .foregroundStyle(.primary)
                                    .frame(width: 15, height: 10)
                            }
                        }
                        .help("Generate Commit Message with AI")
                        .padding(.horizontal)
                        .disabled(cachedDiffRaw.isEmpty)
                    }
                }
                Divider()
                VStack(alignment: .trailing, spacing: 11) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Label(cachedDiffStat?.files.count.formatted() ?? "-" , systemImage: "doc")
                        Label(cachedDiffStat?.insertionsTotal.formatted() ?? "-", systemImage: "plus")
                        Label(cachedDiffStat?.deletionsTotal.formatted() ?? "-", systemImage: "minus")
                    }
                    .font(.caption)
                    Button("Commit") {
                        Task {
                            do {
                                if isAmend {
                                    try await Process.output(GitCommitAmend(directory: folder.url, message: commitMessage))
                                } else {
                                    try await Process.output(GitCommit(directory: folder.url, message: commitMessage))
                                }
                                onCommit()
                            } catch {
                                self.error = error
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.init(.return))
                    .disabled(cachedDiffRaw.isEmpty || commitMessage.isEmpty)
                    Toggle("Amend", isOn: $isAmend)
                        .font(.caption)
                        .padding(.trailing, 6)
                }
                .onChange(of: isAmend) {
                    if isAmend {
                        commitMessage = amendCommit?.rawBody ?? ""
                    } else {
                        commitMessage = ""
                    }
                }
                .padding()
            }
            .background(Color(NSColor.textBackgroundColor))
            .onReceive(NotificationCenter.default.publisher(for: .didSelectCommitMessageSnippetNotification), perform: { notification in
                if let commitMessage = notification.object as? String {
                    self.commitMessage = commitMessage
                }
            })
        }
        .onChange(of: isRefresh, { oldValue, newValue in
            if newValue {
                Task {
                    await updateChanges()
                }
            }
        })
        .onChange(of: appearsActive, { oldValue, newValue in
            if newValue {
                Task {
                    await updateChanges()
                }
            }
        })
        .task(id: cachedDiffRaw) {
            await generateCommitMessage()
        }
        .task {
            await updateChanges()

            do {
                amendCommit = try await Process.output(GitLog(directory: folder.url)).first
            } catch {
                self.error = error
            }
        }
        .errorSheet($error)
    }

    private func updateChanges() async {
        do {
            diffShortStat = try await String(Process.output(GitDiffShortStat(directory: folder.url)).dropLast())
            cachedDiffShortStat = try await String(Process.output(GitDiffShortStat(directory: folder.url, cached: true)).dropLast())
            status = try await Process.output(GitStatus(directory: folder.url))
            cachedDiffRaw = try await Process.output(GitDiffCached(directory: folder.url))
            diffRaw = try await Process.output(GitDiff(directory: folder.url))
            let newCachedDiff = try Diff(raw: cachedDiffRaw)
            cachedDiff = newCachedDiff
            cachedExpandableFileDiffs = newCachedDiff.fileDiffs.withExpansionState(from: cachedExpandableFileDiffs)
            let newDiff = try Diff(raw: diffRaw)
            diff = newDiff
            expandableFileDiffs = newDiff.fileDiffs.withExpansionState(from: expandableFileDiffs)
            cachedDiffStat = try await Process.output(GitDiffNumStat(directory: folder.url, cached: true))
            Task {
                if commitMessage.isEmpty {
                    commitMessage = try await DefaultMergeCommitMessage(directory: folder.url).get()
                }
            }
        } catch {
            updateChangesError = error
        }
    }

    private func restorePatch(_ newDiff: Diff) {
        Task {
            do {
                try await Process.output(GitRestorePatch(directory: folder.url, inputs: newDiff.unstageStrings()))
                await updateChanges()
            } catch {
                self.error = error
            }
        }
    }

    private func addPatch(_ newDiff: Diff) {
        Task {
            do {
                try await Process.output(GitAddPatch(directory: folder.url, inputs: newDiff.stageStrings()))
                await updateChanges()
            } catch {
                self.error = error
            }
        }
    }
    
    private func generateCommitMessage() async {
        suggestedCommitMessage = ""
        do {
            if !cachedDiffRaw.isEmpty {
                let message = try await SystemLanguageModelService().commitMessage(stagedDiff: cachedDiffRaw)
                if !Task.isCancelled {
                    suggestedCommitMessage = message
                }
            }
        } catch {
            Logger().info("\(error.localizedDescription)")
        }
    }
}
