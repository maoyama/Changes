//
//  CommitMessageEditorView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/09/06.
//

import SwiftUI

struct CommitMessageEditor: View {
    var folder: Folder
    @Binding var commitMessage: String
    @Binding var generatedCommitMessage: String
    @Binding var cachedDiffStat: DiffStat?
    @Binding var isAmend: Bool
    @Binding var error: Error?
    @Binding var cachedDiffRaw: String
    @Binding var amendCommit: Commit?

    var generatedCommitMessageReloadAction: () -> Void
    var onCommit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    ZStack(alignment: .topLeading) {
                            TextEditor(text: $commitMessage)
                                .scrollContentBackground(.hidden)
                                .padding(.top, 16)
                                .padding(.horizontal, 12)
                                .font(.body)
                            if commitMessage.isEmpty {
                                Text("Commit Message")
                                    .foregroundColor(.secondary)
                                    .allowsHitTesting(false)
                                    .padding(.top, 14)
                                    .padding(.horizontal, 17)
                            }
                    }
                    .safeAreaBar(edge: .bottom) {
                        if !generatedCommitMessage.isEmpty {
                            CommitMessageGenerationView(
                                commitMessage: $commitMessage,
                                suggestedCommitMessage: $generatedCommitMessage,
                                reloadAction: generatedCommitMessageReloadAction
                            )
                                .font(.callout)
                                .padding(.horizontal)
                        }
                    }
                    CommitMessageSnippetSuggestionView()
                        .padding(.trailing)
                        .font(.callout)
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
        }
        .onReceive(NotificationCenter.default.publisher(for: .didSelectCommitMessageSnippetNotification), perform: { notification in
            if let commitMessage = notification.object as? String {
                self.commitMessage = commitMessage
            }
        })
    }
}
