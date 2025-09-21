//
//  Untitled.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/09.
//

import SwiftUI

struct AmendCommitSheet: View {
    var folder: Folder
    @Binding var showingAmendCommitAt: Commit?
    var onCreate: (() -> Void)
    @State private var message = ""
    @State private var error: Error?

    var body: some View {
        VStack {
            Text("Amend Commit with a New Message")
                .font(.headline)
            VStack(alignment: .leading) {
                HStack {
                    TextEditor(text: $message)
                        .scrollContentBackground(.hidden)
                        .frame(height: 100)
                     // .contentMargins(8, for: .scrollContent)
                     // `contentMargins` not work on macOS. Xcode16.2 and macOS14
                }
                HStack {
                    Button("Cancel") {
                        showingAmendCommitAt = nil
                    }
                    Spacer()
                    Button("Amend") {
                        Task {
                            do {
                                try await Process.output(
                                    GitCommitAmend(directory: folder.url, message: message)
                                )
                                onCreate()
                                showingAmendCommitAt = nil
                            } catch {
                                self.error = error
                            }
                        }
                    }
                    .disabled(message.isEmpty)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.init(.return))
                }
                .padding(.top)
            }
            .frame(width: 400)
            .padding()
        }
        .padding()
        .cornerRadius(8)
        .task {
            message = showingAmendCommitAt?.rawBody ?? ""
        }
        .errorSheet($error)
    }
}
