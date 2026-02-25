//
//  FileNameView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/06.
//

import SwiftUI

struct FileNameView: View {
    @Environment(\.folder) private var current

    var toFilePath: String
    var filePathDisplay: String
    var insertions: Int?
    var deletions: Int?
    var fileURL: URL? {
        current?.appending(path: toFilePath)
    }

    var body: some View {
        HStack {
            if let asset = Language.assetName(filePath: toFilePath) {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18)
            } else {
                Image(systemName: "doc")
                    .frame(width: 18, height: 18)
                    .fontWeight(.heavy)
            }
            Text(filePathDisplay)
                .fontWeight(.bold)
                .font(Font.system(.body, design: .default))
            Button(action: {
                NSWorkspace.shared.open(fileURL!)
            }) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(.secondary)
                    .help("Open " + (fileURL?.absoluteString ?? ""))
            }
            .buttonStyle(.plain)
            if let deletions, deletions > 0 {
                DiffStatBadge(text: "-\(deletions)", color: .red)
            }
            if let insertions, insertions > 0 {
                DiffStatBadge(text: "+\(insertions)", color: .green)
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color(NSColor.separatorColor).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct DiffStatBadge: View {
    var text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontDesign(.monospaced)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

#Preview {
    VStack {
        FileNameView(
            toFilePath: "Sources/MyFeature/File.swift",
            filePathDisplay: "Sources/MyFeature/File.swift",
            insertions: 12,
            deletions: 3
        )
        FileNameView(
            toFilePath: "Sources/MyFeature/File.py",
            filePathDisplay: "Sources/MyFeature/File.py",
            insertions: 5,
            deletions: 0
        )
        FileNameView(
            toFilePath: "Sources/MyFeature/File.rb",
            filePathDisplay: "Sources/MyFeature/File.rb",
            insertions: 0,
            deletions: 8
        )
        FileNameView(
            toFilePath: "Sources/MyFeature/File.rs",
            filePathDisplay: "Sources/MyFeature/File.rs"
        )
    }
    .padding()
}
