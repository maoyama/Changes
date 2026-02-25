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
        DisclosureGroup(isExpanded: $expandableFileDiff.isExpanded) {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                    chunksView(expandableFileDiff.model.chunks, filePath: expandableFileDiff.model.toFilePath)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
            }
        } label: {
            FileNameView(toFilePath: expandableFileDiff.model.toFilePath, filePathDisplay: expandableFileDiff.model.filePathDisplay, insertions: expandableFileDiff.model.insertions, deletions: expandableFileDiff.model.deletions)
                .padding(.leading, 3)
        }
    }

    private func chunksView(_ chunks: [Chunk], filePath: String) -> some View {
        ForEach(chunks) { chunk in
            ChunkView(chunk: chunk, filePath: filePath)
        }
    }
}
