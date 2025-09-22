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
        VStack {
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
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
                                Text(summaryGenerationError?.localizedDescription ?? "")
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                                Spacer()
                            }
                        }
                        if summaryIsResponding && summary.isEmpty {
                            ProgressView()
                                .scaleEffect(x: 0.4, y: 0.4, anchor: .leading)
                                .frame(height: 16)
                                .padding(.leading, 1)
                        }
                        if !summary.isEmpty {
                            Text(summary)
                                .textSelection(.enabled)
                        }
                    }
                    Divider()
                        .padding(.top)
                }
                .padding(.horizontal)
            }
        }
        .onChange(of: fileDiffs.map { $0.model }, initial: true) {
            generateSummaryTask?.cancel()
            generateSummaryTask = Task {
                await generateSummary()
            }
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
