//
//  CommitMessageGenerationView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/08/16.
//

import SwiftUI

struct CommitMessageGenerationView: View {
    @Binding var cachedDiffRaw: String
    @Binding var commitMessage: String
    @Binding var commitMessageIsReponding: Bool
    @Binding var generatedCommitMessage: String
    @State private var error: Error?
    
    var body: some View {
        HStack {
            if commitMessageIsReponding || !generatedCommitMessage.isEmpty || error != nil {
                HStack {
                    Button {
                        Task {
                            await generateCommitMessage()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    Button {
                        generatedCommitMessage = ""
                    } label: {
                        Image(systemName: "xmark")
                    }
                    if commitMessageIsReponding && generatedCommitMessage.isEmpty {
                        ProgressView()
                            .scaleEffect(x: 0.4, y: 0.4, anchor: .center)
                    }
                    ScrollView(.horizontal) {
                        HStack {
                            Text(generatedCommitMessage)
                            if error != nil {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
                                Text(error?.localizedDescription ?? "")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(height: 38)
                    }
                    if !generatedCommitMessage.isEmpty {
                        Button {
                            commitMessage = generatedCommitMessage
                            generatedCommitMessage = ""
                        } label: {
                            Image(systemName: "arrow.up")
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .task(id: cachedDiffRaw) {
            await generateCommitMessage()
        }
        .glassEffect()
        .buttonStyle(.plain)
    }
    
    private func generateCommitMessage() async {
        generatedCommitMessage = ""
        commitMessageIsReponding = true
        error = nil
        do {
            if !cachedDiffRaw.isEmpty {
                 let stream = SystemLanguageModelService().commitMessageStream(stagedDiff: cachedDiffRaw)
                for try await message in stream {
                    if !Task.isCancelled {
                        generatedCommitMessage = message.content.commitMessage ?? ""
                    }
                }
            }
        } catch {
            self.error = error
        }
        commitMessageIsReponding = false
    }
}

#Preview {
    @Previewable @State var cachedDiffRaw = ""
    @Previewable @State var commitMessage = "Hello"
    @Previewable @State var generatedCommitMessage = "Hello"
    @Previewable @State var isRespofing = false

    CommitMessageGenerationView(
        cachedDiffRaw: $cachedDiffRaw,
        commitMessage: $commitMessage,
        commitMessageIsReponding: $isRespofing,
        generatedCommitMessage: $generatedCommitMessage
    )
}

