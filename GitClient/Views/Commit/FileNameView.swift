//
//  FileNameView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/06.
//

import SwiftUI

struct FileNameView: View {
    @Environment(\.folder) private var current

    var fileDiff: FileDiff
    var selectButtonImageSystemName: String
    var onSelectFileDiff: ((FileDiff) -> Void)?
    var fileURL: URL? {
        current?.appending(path: fileDiff.toFilePath)
    }

    var body: some View {
        HStack {
            if let asset = Language.assetName(filePath: fileDiff.toFilePath) {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18)
            } else {
                Image(systemName: "doc")
                    .frame(width: 18, height: 18)
                    .fontWeight(.heavy)
            }
            Text(fileDiff.filePathDisplay)
                .fontWeight(.bold)
                .font(Font.system(.body, design: .default))
                .help(fileDiff.header + "\n" + (fileDiff.extendedHeaderLines + fileDiff.fromFileToFileLines).joined(separator: "\n"))
            Button(action: {
                NSWorkspace.shared.open(fileURL!)
            }) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(.secondary)
                    .help("Open " + (fileURL?.absoluteString ?? ""))
            }
            .buttonStyle(.plain)
            Spacer()
            Button(action: {
                onSelectFileDiff?(fileDiff)
            }) {
                Image(systemName: selectButtonImageSystemName)
                    .foregroundStyle(.secondary)
                    .help("Stage This File")
            }
            .buttonStyle(.plain)
        }
    }
}
