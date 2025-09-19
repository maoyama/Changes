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
    private var notStagedHeaderCaption: String {
        if let untrackedStat = status?.untrackedFilesShortStat, !untrackedStat.isEmpty {
            if diffShortStat.isEmpty {
                return " " + untrackedStat
            } else {
                return diffShortStat + ", " + untrackedStat
            }
        }
        return diffShortStat
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
    @State private var generatedCommitMessage = ""
    @State private var generatedCommitMessageIsResponding = false
    @State private var error: Error?
    @State private var isAmend = false
    @State private var amendCommit: Commit?
    @State private var isStagingChanges = false
    @Binding var isRefresh: Bool
    var onCommit: () -> Void
    var onStash: () -> Void
    
    var body: some View {
        ScrollView {
            if cachedDiff != nil {
                StagedView(
                    fileDiffs: $cachedExpandableFileDiffs,
                    status: cachedDiffShortStat,
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
                    status: notStagedHeaderCaption,
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
        .safeAreaBar(edge: .top, spacing: 0, content: {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        cachedExpandableFileDiffs = cachedExpandableFileDiffs.map {
                            ExpandableModel(isExpanded: true, model: $0.model)
                        }
                        expandableFileDiffs = expandableFileDiffs.map { ExpandableModel(isExpanded: true, model: $0.model)
                        }
                    } label: {
                        Image(systemName: "arrow.up.and.line.horizontal.and.arrow.down")
                    }
                    .buttonStyle(.plain)
                    .help("Expand All Files")
                    Button {
                        cachedExpandableFileDiffs = cachedExpandableFileDiffs.map {
                            ExpandableModel(isExpanded: false, model: $0.model)
                        }
                        expandableFileDiffs = expandableFileDiffs.map { ExpandableModel(isExpanded: false, model: $0.model)
                        }
                    } label: {
                        Image(systemName: "arrow.down.and.line.horizontal.and.arrow.up")
                    }
                    .buttonStyle(.plain)
                    .help("Collapse All Files")
                    Spacer()
                    Button("Stash All") {
                        Task {
                            do {
                                try await Process.output(GitStash(directory: folder.url))
                                onStash()
                            } catch {
                                self.error = error
                            }
                        }
                    }
                    .help("Stash all changes including untracked files")

                    Divider()
                        .frame(height: 16)
                    
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
                    .layoutPriority(2)
                }
                .textSelection(.disabled)
                .padding(.vertical, 10)
                .padding(.horizontal)
                Divider()
            }
        })
        .scrollEdgeEffectStyle(.hard, for: .vertical)
        .safeAreaBar(edge: .bottom, content: {
            CommitMessageEditor(
                folder: folder,
                commitMessage: $commitMessage,
                generatedCommitMessage: $generatedCommitMessage,
                generatedCommitMessageIsResponding: $generatedCommitMessageIsResponding,
                cachedDiffStat: $cachedDiffStat,
                isAmend: $isAmend,
                error: $error,
                cachedDiffRaw: $cachedDiffRaw,
                amendCommit: $amendCommit) {
                    onCommit()
                }
                .frame(height: 140)
        })
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.textBackgroundColor))
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
}
