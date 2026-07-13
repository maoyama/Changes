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
            HStack(spacing: FileDiffHeaderLayout.chevronSpacing) {
                Button {
                    withAnimation {
                        expandableFileDiff.isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(expandableFileDiff.isExpanded ? 90 : 0))
                        .frame(
                            width: FileDiffHeaderLayout.chevronWidth,
                            height: FileDiffHeaderLayout.chevronWidth
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                FileNameView(fileDiff: expandableFileDiff.model)
            }
            .padding(.leading, FileDiffHeaderLayout.headerLeadingPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fileDiffHeaderPosition(id: expandableFileDiff.model.id)
        }
    }

    private func chunksView(_ chunks: [Chunk], filePath: String) -> some View {
        ForEach(chunks) { chunk in
            ChunkView(chunk: chunk, filePath: filePath)
        }
    }
}
