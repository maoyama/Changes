//
//  OpenFileButton.swift
//  GitClient
//

import SwiftUI

struct OpenFileButton: View {
    @Environment(\.folder) private var folder

    var filePath: String

    private var fileURL: URL? {
        folder?.appending(path: filePath)
    }

    var body: some View {
        Button {
            if let fileURL {
                NSWorkspace.shared.open(fileURL)
            }
        } label: {
            Image(systemName: "arrow.right.circle.fill")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help("Open " + (fileURL?.absoluteString ?? ""))
        .disabled(fileURL == nil)
    }
}
