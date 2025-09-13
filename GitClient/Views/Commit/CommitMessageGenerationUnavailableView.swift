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
    @State private var modelNotReadyPopOver = false
    @State private var appleIntelligenceNotEnabled = false
    
    var body: some View {
        switch reason {
        case .modelNotReady:
            Button {
                modelNotReadyPopOver = true
            } label: {
                Image(systemName: "exclamationmark.circle")
            }
            .popover(isPresented: $modelNotReadyPopOver) {
                Text("The model(s) aren’t available on this device.\nModels are downloaded automatically based on factors like network status, battery level, and system load.")
                    .padding()
            }
        case .appleIntelligenceNotEnabled:
            Button {
                appleIntelligenceNotEnabled = true
            } label: {
                Image(systemName: "exclamationmark.circle")
            }
            .popover(isPresented: $appleIntelligenceNotEnabled) {
                Text("Apple Intelligence is not enabled on this system.")
                    .padding()
            }
        case .deviceNotEligible:
            // This device does not support Apple Intelligence.
            EmptyView()
        @unknown default:
            // The model is unavailable for unknown reasons.
            EmptyView()
        }
    }
}

#Preview {
    CommitMessageGenerationUnavailableView(reason: .modelNotReady)
}
