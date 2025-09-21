//
//  DiffSummaryView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/09/22.
//

import SwiftUI

struct DiffSummaryView: View {
    var fileDiffs: [ExpandableModel<FileDiff>]
    @State private var summary = ""
    @State private var summaryIsResponding = false
    @State private var summaryGenerationError: Error?
    @State private var generateSummaryTask: Task<(), Never>?
    @Environment(\.systemLanguageModelAvailability) private var systemLanguageModelAvailability
    
    var body: some View {
        if systemLanguageModelAvailability == .available && (!summary.isEmpty || summaryIsResponding) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 2) {
                            Image(systemName: "apple.intelligence")
                            Text("Summary")
                        }
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Button {
                            generateSummaryTask?.cancel()
                            generateSummaryTask = Task {
                                await generateSummary()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        Button {
                            generateSummaryTask?.cancel()
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
                Divider()
                    .padding(.top)
            }
            .padding(.horizontal)
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
