//
//  CommitDetailHeaderView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/09/18.
//

import SwiftUI

struct CommitDetailHeaderView: View {
    var commit: Commit
    @Binding var mergedIn: Commit?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Text(commit.hash.prefix(5))
                    .textSelection(.disabled)
                    .help(commit.hash)
                    .contextMenu {
                        Button("Copy " + commit.hash) {
                            let pasteboard = NSPasteboard.general
                            pasteboard.declareTypes([.string], owner: nil)
                            pasteboard.setString(commit.hash, forType: .string)
                        }
                    }
                Image(systemName: "arrow.left")
                HStack(spacing: 0) {
                    ForEach(commit.parentHashes, id: \.self) { hash in
                        if hash == commit.parentHashes.first {
                            NavigationLink(commit.parentHashes[0].prefix(5), value: commit.parentHashes[0])
                                .foregroundColor(.accentColor)
                        } else {
                            Text(",")
                                .padding(.trailing, 2)
                            NavigationLink(commit.parentHashes[1].prefix(5), value: commit.parentHashes[1])
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .textSelection(.disabled)
                if let mergedIn {
                    Divider()
                        .frame(height: 10)
                    HStack {
                        Image(systemName: "arrow.triangle.pull")
                        NavigationLink(mergedIn.hash.prefix(5), value: mergedIn.hash)
                            .foregroundColor(.accentColor)
                    }
                    .help("Merged in \(mergedIn.hash.prefix(5))")
                }
                if !commit.tags.isEmpty {
                    Divider()
                        .frame(height: 10)
                    HStack(spacing: 14) {
                        ForEach(commit.tags, id: \.self) { tag in
                            Label(tag, systemImage: "tag")
                        }
                    }
                }
                if !commit.branches.isEmpty {
                    Divider()
                        .frame(height: 10)
                    HStack(spacing: 14) {
                        ForEach(commit.branches, id: \.self) { branch in
                            Label(branch, systemImage: "arrow.triangle.branch")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .foregroundColor(.secondary)
            .buttonStyle(.link)
        }
        .padding(.top, 14)
        .padding(.horizontal)
    }
}
