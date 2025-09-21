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
    @State private var summary = ""
    @State private var summaryIsResponding = false
    @State private var error: Error?
    @State private var summaryGenerationError: Error?
    @Environment(\.systemLanguageModelAvailability) private var systemLanguageModelAvailability
    
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
                    if systemLanguageModelAvailability == .available && (!summary.isEmpty || summaryIsResponding) {
                        VStack(spacing: 0) {
                            ScrollView(.vertical) {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("Summary")
                                            .foregroundStyle(.tertiary)
                                        Spacer()
                                        Button {
                                            Task {
                                                await generateSummary()
                                            }
                                        } label: {
                                            Image(systemName: "arrow.clockwise")
                                        }
                                        Button {
                                            summary = ""
                                        } label: {
                                            Image(systemName: "xmark")
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .font(.callout)
                                    if summaryGenerationError != nil {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.yellow)
                                        Text(summaryGenerationError?.localizedDescription ?? "")
                                            .foregroundStyle(.secondary)
                                            .textSelection(.enabled)
                                    }
                                    Text(summary)
                                        .textSelection(.enabled)
                                }
                            }
                            .scrollIndicators(.hidden)
                            .contentMargins(12)
                            .padding(.horizontal)
                        }
                        .frame(height: 72)
                        .glassEffect()
                        .padding(.horizontal)
                    }
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
        .task(id: fileDiffs, {
            await generateSummary()
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
    
    private func generateSummary() async {
        summary = ""
        summaryIsResponding = true
        summaryGenerationError = nil
        do {
            let diffRaw = fileDiffs.map { fileDiff in
                    fileDiff.model.raw
                }.joined(separator: "\n")
            if !diffRaw.isEmpty {
                 let stream = SystemLanguageModelService().diffSummary(diffRaw)
                for try await text in stream {
                    if !Task.isCancelled {
                        summary = text.content.summary ?? ""
                    }
                }
            }
        } catch {
            summaryGenerationError = error
        }
        summaryIsResponding = false
    }

}

#Preview {
    @Previewable @State var showingStashChanged = false
    return StashChangedContentView(folder: .init(url: URL(string: "file:///maoyama/Projects/")!), showingStashChanged: $showingStashChanged)
}

