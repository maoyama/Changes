//
//  MessageSnippetSuggestionView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/10.
//

import SwiftUI

struct CommitMessageSnippetSuggestionView: View {
    @State private var error: Error?
    @State private var isPresenting = false
    @Environment(\.openWindow) private var openWindow
    @AppStorage(AppStorageKey.commitMessageSnippet.rawValue) var commitMessageSnippet: Data = AppStorageDefaults.commitMessageSnippets
    var decodedCommitMessageSnippet: Array<String> {
        do {
            do {
                return try JSONDecoder().decode(Array<String>.self, from: commitMessageSnippet)
            } catch {
                return []
            }
        }
    }

    var body: some View {
        HStack {
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(decodedCommitMessageSnippet, id: \.self) { snippet in
                        Button(snippet) {
                            NotificationCenter.default.post(name: .didSelectCommitMessageSnippetNotification, object: snippet)
                        }
                        .buttonStyle(.plain)
                        if snippet != decodedCommitMessageSnippet.last {
                            Text("|")
                                .foregroundStyle(.separator)
                        }
                    }
                }
                .font(.callout)
                .padding(.leading, 12)
            }
            .frame(height: 40)
            Button(action: {
                openWindow(id: WindowID.commitMessageSnippets.rawValue)
            }, label: {
                Image(systemName: "list.dash")
            })
        }
        .errorSheet($error)
    }
}

#Preview {
    CommitMessageSnippetSuggestionView()
}
