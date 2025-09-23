//
//  StageFileDiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/03/16.
//

import SwiftUI

struct StageFileDiffView: View {
    @Binding var expandableFileDiff: ExpandableModel<FileDiff>
    var fileDiff: FileDiff {
        expandableFileDiff.model
    }
    var selectButtonImageSystemName: String
    var selectButtonHelp: String
    var onSelectFileDiff: ((FileDiff) -> Void)?
    var onSelectChunk: ((FileDiff, Chunk) -> Void)?

    var body: some View {
        DisclosureGroup(isExpanded: $expandableFileDiff.isExpanded) {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(fileDiff.chunks) { chunk in
                    HStack(spacing: 0) {
                        ChunkView(chunk: chunk, filePath: fileDiff.toFilePath)
                        Spacer(minLength: 0)
                        Button {
                            onSelectChunk?(fileDiff, chunk)
                        } label: {
                            Image(systemName: selectButtonImageSystemName)
                                .frame(width: 20, height: 20)
                        }
                        .buttonStyle(.plain)
                        .help(selectButtonHelp)
                        .padding(.vertical)
                        .disabled(onSelectChunk == nil)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 12)
            if fileDiff.chunks.isEmpty {
                HStack {
                    VStack(alignment: .leading) {
                        Text(fileDiff.header)
                        Text(fileDiff.extendedHeaderLines.joined(separator: "\n"))
                        Text(fileDiff.fromFileToFileLines.joined(separator: "\n"))
                    }
                    Spacer()
                    Button {
                        onSelectFileDiff?(fileDiff)
                    } label: {
                        Image(systemName: selectButtonImageSystemName)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .help(selectButtonHelp)
                    .padding()
                }
            }
        } label: {
            StageFileDiffHeaderView(fileDiff: fileDiff)
                .padding(.leading, 3)
        }
    }
}
