//
//  CommitDetailBottomBar.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/09/18.
//

import SwiftUI

struct CommitDetailBottomBar: View {
    var commit: Commit
    var folder: Folder
    @Binding var fileDiffs: [ExpandableModel<FileDiff>]
    @State private var shortstat = ""

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack {
                Spacer()
                Text(shortstat)
                    .minimumScaleFactor(0.3)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .font(.callout)
            Spacer()
        }
        .frame(height: 40)
        .overlay(alignment: .leading) {
            if !fileDiffs.isEmpty {
                HStack {
                    Button {
                        fileDiffs = fileDiffs.map {
                            ExpandableModel(isExpanded: true, model: $0.model)
                        }
                    } label: {
                        Image(systemName: "arrow.up.and.line.horizontal.and.arrow.down")
                    }
                    .help("Expand All Files")
                    Button {
                        fileDiffs = fileDiffs.map {
                            ExpandableModel(isExpanded: false, model: $0.model)
                        }
                    } label: {
                        Image(systemName: "arrow.down.and.line.horizontal.and.arrow.up")
                    }
                    .help("Collapse All Files")
                }
                .padding()
                .buttonStyle(.plain)
            }
        }
        .onChange(of: commit, initial: true, { _, commit in
            Task {
                shortstat = (try? await Process.output(GitShowShortstat(directory: folder.url, object: commit.hash))) ?? ""
            }
        })
    }
}
