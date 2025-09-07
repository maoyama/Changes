//
//  CommitMessageGenerationView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/08/16.
//

import SwiftUI
import os

struct CommitMessageGenerationView: View {
    @Binding var cachedDiffRaw: String
    @Binding var commitMessage: String
    @Binding var commitMessageIsReponding: Bool
    @Binding var generatedCommitMessage: String
    
    var body: some View {
        HStack {
            if commitMessageIsReponding || !generatedCommitMessage.isEmpty {
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
                        Text(generatedCommitMessage)
                            .frame(height: 38)
                    }
                    Button {
                        commitMessage = generatedCommitMessage
                        generatedCommitMessage = ""
                    } label: {
                        Image(systemName: "arrow.up")
                    }
                }
                .padding(.horizontal)
            } else {
                
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
            Logger().info("\(error.localizedDescription)")
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
