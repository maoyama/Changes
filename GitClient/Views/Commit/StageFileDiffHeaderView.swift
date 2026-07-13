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
    var onSelectFileDiff: ((FileDiff) -> Void)?

    var body: some View {
        HStack {
            FileNameView(
                fileDiff: fileDiff,
                selectButtonImageSystemName: selectButtonImageSystemName,
                onSelectFileDiff: onSelectFileDiff
            )
        }
        .background(Color(NSColor.textBackgroundColor).opacity(0.98))
    }
}
