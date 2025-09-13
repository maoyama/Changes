//
//  CommitMessageGenerationView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/08/16.
//

import SwiftUI
import FoundationModels

struct CommitMessageGenerationView: View {
    @Environment(\.appearsActive) private var appearsActive
    @Binding var cachedDiffRaw: String
    @Binding var commitMessage: String
    @Binding var commitMessageIsReponding: Bool
    @Binding var generatedCommitMessage: String
    @State private var modelAvailability = SystemLanguageModelService().availability
    
    var body: some View {
        HStack {
            switch modelAvailability {
            case .available:
                CommitMessageGenerationContentView(
                    cachedDiffRaw: $cachedDiffRaw,
                    commitMessage: $commitMessage,
                    commitMessageIsReponding: $commitMessageIsReponding,
                    generatedCommitMessage: $generatedCommitMessage
                )
            case .unavailable(let reason):
                CommitMessageGenerationUnavailableView(reason: reason)
            }
//            CommitMessageGenerationUnavailableView(reason: .deviceNotEligible)
        }
        .onChange(of: appearsActive) {
            modelAvailability = SystemLanguageModelService().availability
        }
    }
}
