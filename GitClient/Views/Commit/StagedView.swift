//
//  StagedView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/07.
//

import SwiftUI

struct StagedView: View {
    @Binding var fileDiffs: [ExpandableModel<FileDiff>]
    var status: String
    var onSelectFileDiff: ((FileDiff) -> Void)?
    var onSelectChunk: ((FileDiff, Chunk) -> Void)?
    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if fileDiffs.isEmpty {
                LazyVStack(alignment: .center) {
                    Label("No Changes", systemImage: "plusminus")
                        .foregroundStyle(.secondary)
                        .padding()
                        .padding()
                        .padding(.trailing)
                }
            } else {
                StagedFileDiffView(
                    expandableFileDiffs: $fileDiffs,
                    selectButtonImageSystemName: "minus.circle",
                    selectButtonHelp: "Unstage This Hunk",
                    onSelectFileDiff: onSelectFileDiff,
                    onSelectChunk: onSelectChunk
                )
                .padding(.leading, 4)
                .padding(.top)
            }
        } label: {
            SectionHeader(title: "Staged Changes", callout: status)
                .padding(.leading, 3)
        }
        .padding(.horizontal)
    }
}
