//
//  FileNameView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/06.
//

import SwiftUI

struct FileNameView: View {
    var fileDiff: FileDiff

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
            OpenFileButton(filePath: fileDiff.toFilePath)
        }
    }
}
