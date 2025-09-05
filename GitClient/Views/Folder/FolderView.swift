//
//  CommitsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import SwiftUI
import Foundation
import AppKit

struct FolderView: View {
    var folder: Folder
    @Binding var selectionLog: Log?
    @Binding var subSelectionLogID: String?
    @Binding var isRefresh: Bool
    @State private var logStore = LogStore()
    @State private var syncState = SyncState()
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showing = FolderViewShowing()
    @State private var branch: Branch?
    @State private var selectionLogID: String?
    @State private var searchTokens: [SearchToken] = []
    @State private var searchText = ""
    @State private var searchTask: Task<(), Never>?
    @State private var showGraph = false
    @AppStorage(AppStorageKey.searchTokenHisrtory.rawValue) var searchTokenHistory: Data?
    private var decodedSearchTokenHistory: [SearchToken] {
        guard let searchTokenHistory else { return [] }
        do {
            return try JSONDecoder().decode([SearchToken].self, from: searchTokenHistory)
        } catch {
            return []
        }
    }
    private var suggestSearchToken: [SearchToken] {
        decodedSearchTokenHistory.filter { !searchTokens.contains($0)}
    }

    var body: some View {
        VStack(spacing: 0) {
            if showGraph {
                CommitGraphView(
                    logStore: $logStore,
                    selectionLogID: $selectionLogID,
                    subSelectionLogID: $subSelectionLogID,
                    showing: $showing,
                    isRefresh: $isRefresh
                )
            } else {
                CommitLogView(
                    logStore: $logStore,
                    selectionLogID: $selectionLogID,
                    subSelectionLogID: $subSelectionLogID,
                    showing: $showing,
                    isRefresh: $isRefresh,
                    error: $error
                )
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .bottom)
        .safeAreaBar(edge: .bottom, spacing: 0) {
            HStack(spacing: 0) {
                Spacer()
                countText()
                    .font(.callout)
                Spacer()
            }
            .overlay(alignment: .trailing, content: {
                Button(action: {
                    showGraph.toggle()
                }) {
                    Image(systemName: showGraph ? "point.3.filled.connected.trianglepath.dotted" : "point.3.connected.trianglepath.dotted")
                        .font(.title3)
                        .rotationEffect(.init(degrees: 270))
                        .foregroundStyle( showGraph ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.accessoryBar)
                .padding(.horizontal, 8)
                .help("Commit Graph")
            })
            .frame(height: 40)
        }
        .overlay(content: {
            if logStore.commits.isEmpty && !searchTokens.isEmpty {
                Text("No Commits History")
                    .foregroundColor(.secondary)
            }
        })
        .searchable(text: $searchText, editableTokens: $searchTokens, prompt: "Search Commits", token: { $token in
            Picker(selection: $token.kind) {
                ForEach(SearchKind.allCases, id: \.self) { kind in
                    Text(kind.shortLabel)
                        .tag(kind)
                        .help(kind.help)
                }
            } label: {
                Text(token.text)
            }
        })
        .searchSuggestions({
            if searchText.isEmpty {
                if !suggestSearchToken.isEmpty {
                    Section("History") {
                        ForEach(suggestSearchToken) { token in
                            VStack(alignment: .leading) {
                                Text(token.kind.label)
                                    .foregroundStyle(.secondary)
                                Text(token.text)
                            }
                                .searchCompletion(token)
                                .contextMenu {
                                    Button("Use as Text") {
                                        if searchText.isEmpty {
                                            searchText = token.text
                                        } else {
                                            searchText += " " + token.text
                                        }
                                    }
                                    Button("Delete") {
                                        var tokens = decodedSearchTokenHistory
                                        tokens.removeAll { $0 == token }
                                        do {
                                            try self.searchTokenHistory = JSONEncoder().encode(tokens)
                                        } catch {
                                            self.error = error
                                        }
                                    }
                                }
                        }
                    }
                }
            } else {
                ForEach(SearchKind.allCases, id: \.self) { kind in
                    VStack(alignment: .leading) {
                        Text(kind.label)
                            .foregroundStyle(.secondary)
                        Text(searchText)
                    }
                        .searchCompletion(SearchToken(kind: kind, text: searchText))
                        .help(kind.help)
                }
            }
        })
        .task {
            await refreshModels()
        }
        .onChange(of: searchTokens, { oldValue, newValue in
            searchTokens = SearchTokensHandler.normalize(oldTokens: oldValue, newTokens: newValue)
            logStore.searchTokens = searchTokens
            searchTask?.cancel()
            searchTask = Task {
                isLoading = true
                await refreshModels()
                isLoading = false
            }
            saveSearchTokenHistory(oldValue: oldValue, newValue: newValue)
        })
        .onChange(of: selectionLogID, {
            selectionLog = logStore.logs().first { $0.id == selectionLogID }
        })
        .onChange(of: selectionLog, {
            if selectionLog == nil {
                selectionLogID = nil
                subSelectionLogID = nil
            }
        })
        .onChange(of: isRefresh, { oldValue, newValue in
            if newValue {
                Task {
                    await refreshModels()
                    isRefresh = false
                }
            }
        })
        .errorSheet($error)
        .errorSheet($logStore.error)
        .sheet(item: $showing.createNewBranchFrom, content: { _ in
            CreateNewBranchSheet(folder: folder, showingCreateNewBranchFrom: $showing.createNewBranchFrom) {
                Task {
                    await refreshModels()
                }
            }
        })
        .sheet(item: $showing.renameBranch, onDismiss: {
            Task {
                await updateModels()
            }
        }, content: { _ in
            RenameBranchSheet(folder: folder, showingRenameBranch: $showing.renameBranch)
        })
        .sheet(item: $showing.createNewTagAt, content: { _ in
            CreateNewTagSheet(folder: folder, showingCreateNewTagAt: $showing.createNewTagAt) {
                Task {
                    await refreshModels()
                }
            }
        })
        .sheet(item: $showing.amendCommitAt, content: { _ in
            AmendCommitSheet(folder: folder, showingAmendCommitAt: $showing.amendCommitAt) {
                Task {
                    await refreshModels()
                }
            }
        })
        .sheet(isPresented: $showing.stashChanged, content: {
            StashChangedView(folder: folder, showingStashChanged: $showing.stashChanged)
        })
        .navigationTitle(branch?.name ?? "")
        .toolbar {
            if isLoading {
                ToolbarItem(placement: .primaryAction) {
                    ProgressView()
                        .scaleEffect(x: 0.5, y: 0.5, anchor: .center)
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .principal) {
                    branchesButton()
                }
                ToolbarItem(placement: .principal) {
                    addBranchButton()
                }
                ToolbarSpacer(.fixed, placement: .principal)
                ToolbarItem(placement: .principal) {
                    tagButton()
                }
                ToolbarSpacer(.fixed, placement: .principal)
                ToolbarItem(placement: .principal) {
                    stashButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    pullButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    pushButton()
                }
            }
        }
        .onChange(of: showing.stashChanged) { _, new in
            if !new {
                Task {
                    await updateModels()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            Task {
                await updateModels()
            }
        }
    }

    fileprivate func refreshModels() async {
        do {
            branch = try await Process.output(GitBranch(directory: folder.url)).current
            logStore.directory = folder.url
            syncState.folderURL = folder.url
            syncState.branch = branch
            if Task.isCancelled {
                throw CancellationError()
            }
            await logStore.refresh()
            if Task.isCancelled {
                throw CancellationError()
            }
            if let selectionLog {
                let newSelection = logStore.logs().first { $0.id == selectionLog.id }
                self.selectionLog = newSelection
            }
            try await syncState.sync()
        } catch {
            if !Task.isCancelled {
                self.error = error
                branch = nil
                logStore.removeAll()
            }
        }
    }

    fileprivate func updateModels() async {
        do {
            let currentBranch = try await Process.output(GitBranch(directory: folder.url)).current
            guard currentBranch == branch else { // Support for external changes made outside the app (e.g., via CLI)
                await refreshModels()
                return
            }
            await logStore.update()
            if let selectionLog {
                let newSelection = logStore.logs().first { $0.id == selectionLog.id }
                self.selectionLog = newSelection
            }
            try await syncState.sync()
        } catch {
            self.error = error
        }
    }


    fileprivate func branchesButton() -> some View {
        Button {
                showing.branches.toggle()
            } label: {
                Image(systemName: "arrow.trianglehead.branch")
            }
            .help("Select Branch")
            .popover(isPresented: $showing.branches) {
                TabView {
                    BranchesView(
                        folder: folder,
                        branch: branch,
                        onSelect: { branch in
                            showing.branches = false
                            Task {
                                do {
                                    try await Process.output(
                                        GitSwitch(directory: folder.url, branchName: branch.name)
                                    )
                                } catch {
                                    self.error = error
                                }
                                await refreshModels()
                            }
                        }, onSelectMergeInto: { mergeIntoBranch in
                            showing.branches = false
                            Task {
                                do {
                                    try await Process.output(GitMerge(directory: folder.url, branchName: mergeIntoBranch.name))
                                } catch {
                                    self.error = error
                                }
                                await refreshModels()
                            }
                        },
                        onSelectNewBranchFrom: { from in
                            showing.createNewBranchFrom = from
                        },
                        onSelectRenameBranch: { old in
                            showing.renameBranch = old
                        }
                    )
                        .tabItem {
                            Text("Local")
                        }
                    BranchesView(
                        folder: folder,
                        branch: branch,
                        isRemote: true,
                        onSelect: { branch in
                            showing.branches = false
                            Task {
                                do {
                                    try await Process.output(
                                        GitSwitchDetach(directory: folder.url, branchName: branch.name)
                                    )
                                } catch {
                                    self.error = error
                                }
                                await refreshModels()
                            }
                        }, onSelectMergeInto: { mergeIntoBranch in
                            showing.branches = false
                            Task {
                                do {
                                    try await Process.output(GitMerge(directory: folder.url, branchName: mergeIntoBranch.name))
                                } catch {
                                    self.error = error
                                }
                                await refreshModels()
                            }
                        },
                        onSelectNewBranchFrom: { from in
                            showing.createNewBranchFrom = from
                        }
                    )
                        .tabItem {
                            Text("Remotes")
                        }
                }
                .frame(width: 300, height: 660)
                .padding()
            }

    }

    fileprivate func saveSearchTokenHistory(oldValue: [SearchToken], newValue: [SearchToken]) {
        let newHistory = SearchTokensHandler.searchTokenHistory(currentHistory: decodedSearchTokenHistory, old: oldValue, new: newValue)
        guard newHistory != decodedSearchTokenHistory else { return }
        do {
            try self.searchTokenHistory = JSONEncoder().encode(newHistory)
        } catch {
            self.error = error
        }
    }

    fileprivate func addBranchButton() -> some View {
        Button {
            showing.createNewBranchFrom = branch
        } label: {
            Image(systemName: "plus")
        }
        .help("Create New Branch")
    }

    fileprivate func tagButton() -> some View {
        Button {
            showing.tags.toggle()
        } label: {
            Image(systemName: "tag")
        }
        .help("Show Tags")
        .popover(isPresented: $showing.tags, content: {
            TagsView(folder: folder, showingTags: $showing.tags)
        })
        .onChange(of: showing.tags) { oldValue, newValue in
            if oldValue && !newValue {
                Task {
                    await refreshModels()
                }
            }
        }
    }

    fileprivate func stashButton() -> some View {
        Button {
            showing.stashChanged.toggle()
        } label: {
            Image(systemName: "tray")
        }
        .help("Show Stashed Changes")
    }

    fileprivate func badge() -> some View {
        return Circle()
            .fill(Color.accentColor)
            .foregroundColor(.white)
            .frame(width: 6)
            .offset(x: 2, y: -2)
    }
    
    fileprivate func pullButton() -> some View {
        return Button {
            isLoading = true
            Task {
                do {
                    try await GitFetchExecutor.shared.execute(GitPull(directory: folder.url, refspec: branch!.name))
                    syncState.shouldPull = false
                    isLoading = false
                    await refreshModels()
                } catch {
                    isLoading = false
                    self.error = error
                }
            }
        } label: {
            Image(systemName: "arrow.down")
                .overlay(alignment: .topTrailing, content: {
                    badge()
                        .animation(.default, body: { content in
                            content
                                .opacity(syncState.shouldPull ? 1 : 0)
                        })
                })
        }
        .help("Pull origin \(branch?.name ?? "")" )
    }

    fileprivate func pushButton() -> some View {
        return Button {
            isLoading = true
            Task {
                do {
                    try await Process.output(GitPush(directory: folder.url))
                    syncState.shouldPush = false
                    isLoading = false
                    await updateModels()
                } catch {
                    isLoading = false
                    self.error = error
                }
            }
        } label: {
            Image(systemName: "arrow.up")
                .overlay(alignment: .topTrailing, content: {
                        badge()
                            .animation(.default, body: { content in
                                content
                                    .opacity(syncState.shouldPush ? 1 : 0)
                            })
                })
        }
        .help("Push origin HEAD")
    }

    fileprivate func countText() -> some View {
        if let count = logStore.totalCommitsCount {
            let subText: String
            if count == 1 {
                subText = "Commit"
            } else {
                subText = "Commits"
            }
            return Text("\(count) \(subText)")
        } else {
            return Text("")
        }
    }
}

struct CommitsView_Previews: PreviewProvider {
    @State static var selection: Log?
    @State static var subSelection: String?
    @State static var refresh = false

    static var previews: some View {
        FolderView(
            folder: .init(url: URL(string: "file:///maoyama/Projects/")!),
            selectionLog: $selection,
            subSelectionLogID: $subSelection,
            isRefresh: $refresh
        )
    }
}
