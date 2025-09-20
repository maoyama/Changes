//
//  StashChangedContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/16.
//

import SwiftUI

struct StashChangedContentView: View {
    var folder: Folder
    @Binding var showingStashChanged: Bool
    var stashList: [Stash]?
    var onTapDropButton: ((Stash) -> Void)?
    @State private var selectionStashID: Int?
    @State private var fileDiffs: [ExpandableModel<FileDiff>] = []
    @State private var error: Error?

    var body: some View {
        NavigationSplitView {
            List(selection: $selectionStashID) {
                Text("Stash Changed")
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(2)
                if let stashList {
                    if stashList.isEmpty {
                        Text("No Content")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(stashList) { stash in
                            Text(stash.message)
                                .lineLimit(3)
                                .contextMenu {
                                    Button("Drop") {
                                        onTapDropButton?(stash)
                                        selectionStashID = nil
                                    }
                                }
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(ideal: 200)
        } detail: {
            ScrollView {
                VStack(spacing: 0) {
                    if selectionStashID != nil {
                        StashChangedDetailContentView(fileDiffs: $fileDiffs)
                    } else {
                        Spacer()
                        Text("No Selection")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 250)
                    }
                    Spacer(minLength: 0)
                }
            }
            .scrollEdgeEffectStyle(.soft, for: .bottom)
            .safeAreaBar(edge: .bottom, content: {
                VStack (spacing: 0) {
                    HStack {
                        Button {
                            fileDiffs = fileDiffs.map {
                            ExpandableModel(isExpanded: true, model: $0.model)
                            }
                        } label: {
                            Image(systemName: "arrow.up.and.line.horizontal.and.arrow.down")
                        }
                        .help("Expand All Files")
                        .buttonStyle(.plain)
                        Button {
                            fileDiffs = fileDiffs.map {
                                ExpandableModel(isExpanded: false, model: $0.model)
                            }
                        } label: {
                            Image(systemName: "arrow.down.and.line.horizontal.and.arrow.up")
                        }
                        .help("Collapse All Files")
                        .buttonStyle(.plain)
                        Spacer()
                        Button("Cancel") {
                            showingStashChanged.toggle()
                        }
                        Button("Apply") {
                            Task {
                                do {
                                    try await Process.output(GitStashApply(directory: folder.url, index: selectionStashID!))
                                    showingStashChanged = false
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.init(.defaultAction))
                        .disabled(selectionStashID == nil)
                    }
                    .padding()
                }
            })
        }
        .background(Color(NSColor.textBackgroundColor))
        .task(id: selectionStashID, {
            await updateDiff()
        })
        .frame(width: 800, height: 700)
        .errorSheet($error)
    }

    private func updateDiff() async {
        do {
            if let index = selectionStashID {
                let diff = try await Process.output(GitStashShowDiff(directory: folder.url, index: index))
                fileDiffs = try Diff(raw: diff).fileDiffs.map { ExpandableModel(isExpanded: true, model: $0) }
            } else {
                fileDiffs = []
            }
        } catch {
            self.error = error
        }
    }
}

#Preview {
    @Previewable @State var showingStashChanged = false
    return StashChangedContentView(folder: .init(url: URL(string: "file:///maoyama/Projects/")!), showingStashChanged: $showingStashChanged)
}

