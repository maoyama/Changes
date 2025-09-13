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
                switch reason {
                case .modelNotReady:
                    Text("The model(s) aren’t available on this device. Models are downloaded automatically based on factors like network status, battery level, and system load.")
                case .appleIntelligenceNotEnabled:
                    Text("Apple Intelligence is not enabled on this system.")
                case .deviceNotEligible:
                    Text("This device does not support Apple Intelligence.")
                @unknown default:
                    Text("The model is unavailable for unknown reasons.")
                }
            }
        }
        .onChange(of: appearsActive) {
            modelAvailability = SystemLanguageModelService().availability
        }
    }
}
