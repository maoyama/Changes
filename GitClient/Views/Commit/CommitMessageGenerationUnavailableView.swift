//
//  CommitMessageGenerationUnavailableView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/09/13.
//

import SwiftUI
import FoundationModels

struct CommitMessageGenerationUnavailableView: View {
    var reason: SystemLanguageModel.Availability.UnavailableReason
    
    var body: some View {
        HStack {
            switch reason {
            case .modelNotReady:
                Text("The model(s) aren’t available on this device. Models are downloaded automatically based on factors like network status, battery level, and system load.")
            case .appleIntelligenceNotEnabled:
                Text("Apple Intelligence is not enabled on this system.")
            case .deviceNotEligible:
                // This device does not support Apple Intelligence.
                EmptyView()
            @unknown default:
                // The model is unavailable for unknown reasons.
                EmptyView()
            }
        }
    }
}

#Preview {
    CommitMessageGenerationUnavailableView(reason: .modelNotReady)
}
