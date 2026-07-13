//
//  FileDiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/03/16.
//

import SwiftUI

struct FileDiffView: View {
    @Binding var expandableFileDiff: ExpandableModel<FileDiff>

    var body: some View {
        Section {
            if expandableFileDiff.isExpanded {
                LazyVStack(alignment: .leading, spacing: 0) {
                    chunksView(
                        expandableFileDiff.model.chunks,
                        filePath: expandableFileDiff.model.toFilePath
                    )
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
            }
        } header: {
            FileDiffHeaderView(
                isExpanded: $expandableFileDiff.isExpanded,
                fileDiff: expandableFileDiff.model
            )
        }
    }

    private func chunksView(_ chunks: [Chunk], filePath: String) -> some View {
        ForEach(chunks) { chunk in
            ChunkView(chunk: chunk, filePath: filePath)
        }
    }
}
