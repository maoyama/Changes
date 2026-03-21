//
//  CommitRowView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/10.
//

import SwiftUI

struct CommitRowView: View {
    var commit: Commit

    var body: some View {
        VStack (alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text(commit.title)
                Spacer()
                if !commit.tags.isEmpty {
                    Image(systemName: "tag")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
            }
            HStack {
                Icon(size: .small, authorEmail: commit.authorEmail, authorInitial: String(commit.author.initial.prefix(1)))
                Text(commit.author)
                Spacer()
                Text(commit.authorDateRelative)
            }
            .lineLimit(1)
            .foregroundStyle(.tertiary)
        }
    }
}
