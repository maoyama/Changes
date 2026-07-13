//
//  FileDiffHeaderView.swift
//  GitClient
//
//  Created by Codex on 2026/07/13.
//

import SwiftUI

struct FileDiffHeaderView: View {
    @Binding var isExpanded: Bool
    var fileDiff: FileDiff
    var trailingActionImageSystemName: String?
    var trailingActionHelp: String?
    var onTrailingAction: (() -> Void)?

    private var hasTrailingAction: Bool {
        trailingActionImageSystemName != nil
    }

    var body: some View {
        Group {
            if hasTrailingAction {
                headerContent
                    .padding(.leading, 3)
                    .padding(.vertical, 8)
                    .padding(.trailing, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.textBackgroundColor).opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
            } else {
                headerContent
                    .padding(.leading, 3)
                    .padding(.trailing, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.textBackgroundColor).opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var headerContent: some View {
        HStack(spacing: 4) {
            Button {
                isExpanded.toggle()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .frame(width: 16, height: 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            FileNameView(fileDiff: fileDiff)

            if let trailingActionImageSystemName {
                Spacer(minLength: 0)

                Button {
                    onTrailingAction?()
                } label: {
                    Image(systemName: trailingActionImageSystemName)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(trailingActionHelp ?? "")
            }
        }
    }
}
