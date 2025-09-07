//
//  CommitMessageGenerationView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/08/16.
//

import SwiftUI

struct CommitMessageGenerationView: View {
    @Binding var commitMessage: String
    @Binding var suggestedCommitMessage: String
    var reloadAction: () -> Void
    
    var body: some View {
        HStack {
            HStack(spacing: 16) {
                ScrollView(.horizontal) {
                    Text(suggestedCommitMessage)
                        .frame(height: 40)
                }
                Button {
                    commitMessage = suggestedCommitMessage
                    suggestedCommitMessage = ""
                } label: {
                    Image(systemName: "arrow.up")
                }
            }
            .padding(.horizontal)
            .glassEffect()
            HStack {
                Button {
                    reloadAction()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                Button {
                    suggestedCommitMessage = ""
                } label: {
                    Image(systemName: "xmark")
                }
            }
            .frame(height: 40)
            .padding(.horizontal)
            .glassEffect()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var commitMessage = "Hello"
    @Previewable @State var suggestedCommitMessage = "Hello"
    
    CommitMessageGenerationView(
        commitMessage: $commitMessage,
        suggestedCommitMessage: $suggestedCommitMessage
    ) {}
}
