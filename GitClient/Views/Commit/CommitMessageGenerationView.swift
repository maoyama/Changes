//
//  CommitMessageGenerationView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/08/16.
//

import SwiftUI
import FoundationModels

struct CommitMessageGenerationView: View {
    @Environment(\.systemLanguageModelAvailability) private var systemLanguageModelAvailability
    @Binding var cachedDiffRaw: String
    @Binding var commitMessage: String
    @Binding var commitMessageIsReponding: Bool
    @Binding var generatedCommitMessage: String
    
    var body: some View {
        HStack {
            switch systemLanguageModelAvailability {
            case .available:
                CommitMessageGenerationContentView(
                    cachedDiffRaw: $cachedDiffRaw,
                    commitMessage: $commitMessage,
                    commitMessageIsReponding: $commitMessageIsReponding,
                    generatedCommitMessage: $generatedCommitMessage
                )
            case .unavailable(let reason):
                HStack {
                    Spacer()
                    CommitMessageGenerationUnavailableView(reason: reason)
                }.buttonStyle(.plain)
            }
        }
    }
}
