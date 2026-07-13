//
//  StageFileDiffHeaderView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/02/22.
//

import SwiftUI

struct StageFileDiffHeaderView: View {
    var fileDiff: FileDiff
    var selectButtonImageSystemName: String
    var selectButtonHelp: String
    var onSelectFileDiff: ((FileDiff) -> Void)?

    var body: some View {
        HStack {
            FileNameView(fileDiff: fileDiff)
            Button(action: {
                onSelectFileDiff?(fileDiff)
            }) {
                Image(systemName: selectButtonImageSystemName)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(selectButtonHelp)
        }
        .background(Color(NSColor.textBackgroundColor).opacity(0.98))
    }
}
