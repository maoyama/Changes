//
//  StageFileDiffHeaderView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/02/22.
//

import SwiftUI

struct StageFileDiffHeaderView: View {
    var fileDiff: FileDiff

    var body: some View {
        HStack {
            FileNameView(toFilePath: fileDiff.toFilePath, filePathDisplay: fileDiff.filePathDisplay, isDeletedFile: fileDiff.isDeletedFile, insertions: fileDiff.insertions, deletions: fileDiff.deletions)
                .help(fileDiff.header + "\n" + (fileDiff.extendedHeaderLines + fileDiff.fromFileToFileLines).joined(separator: "\n"))
            Spacer()
        }
        .background(Color(NSColor.separatorColor).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
