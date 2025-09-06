//
//  ContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/17.
//

import SwiftUI

struct ContentView: View {
    @AppStorage(AppStorageKey.folder.rawValue) var folders: Data?
    private var decodedFolders: [Folder] {
        guard let folders else { return [] }
        do {
           return try JSONDecoder().decode([Folder].self, from: folders)
        } catch {
            return []
        }
    }
    @State private var selectionFolderURL: URL?
    private var selectionFolder: Folder? {
        guard let selectionFolderURL = selectionFolderURL else { return nil}
        return decodedFolders.first(where: { $0.url == selectionFolderURL })
    }
    @State private var selectionLog: Log?
    @State private var subSelectionLogID: String?
    @State private var folderIsRefresh = false
    @State private var error: Error?

    var body: some View {
        NavigationSplitView {
            VStack {
                if decodedFolders.isEmpty {
                    VStack {
                        Spacer()
                        Spacer()
                            .frame(height: 60)
                        Text("No Project Folder Added")
                        Text("Please add a folder that contains a Git repository.")
                            .font(.caption)
                            .padding(.top, 2)
                        Spacer()
                    }
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding()
                } else {
                    List(decodedFolders, id: \.url, selection: $selectionFolderURL) { folder in
                        Label(folder.displayName, systemImage: "folder")
                            .help(folder.url.path)
                            .contextMenu {
                                Button("Delete") {
                                    var folders = decodedFolders
                                    folders.removeAll { $0 == folder }
                                    do {
                                        try self.folders = JSONEncoder().encode(folders)
                                    } catch {
                                        self.error = error
                                    }
                                }
                            }
                    }
                }
            }
            .safeAreaBar(edge: .bottom, content: {
                HStack {
                    Button {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.canCreateDirectories = false
                        panel.begin { (response) in
                            if response == .OK {
                                Task { @MainActor in
                                    for fileURL in panel.urls {
                                        let chooseFolder = Folder(url: fileURL)
                                        var folders = decodedFolders
                                        folders.removeAll { $0 == chooseFolder }
                                        folders.insert(chooseFolder, at: 0)
                                        do {
                                            try self.folders = JSONEncoder().encode(folders)
                                        } catch {
                                            self.error = error
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                    .help("Add Project Folder")
                    .padding()
                    Spacer()
                }
            })
        } content: {
            if let folder = selectionFolder {
                FolderView(
                    folder: folder,
                    selectionLog: $selectionLog,
                    subSelectionLogID: $subSelectionLogID,
                    isRefresh: $folderIsRefresh
                )
                .id(folder)
            } else {
                Text("No Folder Selection")
                    .foregroundColor(.secondary)
            }
        } detail: {
            if let selectionLog, let subSelectionLogID {
                CommitDiffView(selectionLogID: selectionLog.id, subSelectionLogID: subSelectionLogID)
            } else if let selectionFolder {
                switch selectionLog {
                case .notCommitted:
                    CommitCreateView(
                        folder: selectionFolder,
                        isRefresh: $folderIsRefresh,
                        onCommit: {
                            self.selectionLog = nil
                            folderIsRefresh = true
                        },
                        onStash: {
                            self.selectionLog = nil
                            folderIsRefresh = true
                        }
                    )
                case .committed(let commit):
                    CommitDetailStackView(commit: commit, folder: selectionFolder)
                case nil:
                    Text("No Selection")
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 300)
        .onChange(of: selectionFolder, {
            selectionLog = nil
        })
        .errorSheet($error)
        .environment(\.folder, selectionFolderURL)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
