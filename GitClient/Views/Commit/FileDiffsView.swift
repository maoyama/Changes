//
//  FileDiffsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/04.
//

import SwiftUI

struct FileDiffsView: View {
    @Binding var expandableFileDiffs: [ExpandableModel<FileDiff>]
    @Environment(\.expandAllFiles) private var expandAllFilesID: UUID?
    @Environment(\.collapseAllFiles) private var collapseAllFilesID: UUID?

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach($expandableFileDiffs, id: \.self) { $expandedFileDiff in
                FileDiffView(expandableFileDiff: $expandedFileDiff)
            }
            .padding(.top, 6)
            .onChange(of: expandAllFilesID) { _, _ in
                expandableFileDiffs = expandableFileDiffs.map { ExpandableModel(isExpanded: true, model: $0.model)}
            }
            .onChange(of: collapseAllFilesID) { _, _ in
                expandableFileDiffs = expandableFileDiffs.map { ExpandableModel(isExpanded: false, model: $0.model)}
            }
        }
        .font(Font.system(.body, design: .monospaced))
        .padding(.top)
    }
}
