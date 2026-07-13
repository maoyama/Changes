//
//  FileDiffStickyHeaderModifier.swift
//  GitClient
//
//  Created by Codex on 2026/07/13.
//

import SwiftUI

private struct FileDiffHeaderPosition: Equatable {
    var id: String
    var minY: CGFloat
}

private struct FileDiffHeaderPositionKey: PreferenceKey {
    static let defaultValue: [FileDiffHeaderPosition] = []

    static func reduce(value: inout [FileDiffHeaderPosition], nextValue: () -> [FileDiffHeaderPosition]) {
        value.append(contentsOf: nextValue())
    }
}

private enum FileDiffStickyHeaderCoordinateSpace {
    static let name = "FileDiffStickyHeaderCoordinateSpace"
}

private struct FileDiffStickyHeaderModifier: ViewModifier {
    var fileDiffs: [FileDiff]

    @State private var headerPositions: [FileDiffHeaderPosition] = []
    @State private var stickyFileDiff: FileDiff?

    private var fileDiffIDs: [String] {
        fileDiffs.map(\.id)
    }

    private var currentFileDiff: FileDiff? {
        let switchY: CGFloat = 0
        if let currentHeaderID = headerPositions.last(where: { $0.minY <= switchY })?.id {
            return fileDiffs.first { $0.id == currentHeaderID }
        }
        guard
            let nextHeader = headerPositions.first(where: { $0.minY > switchY }),
            let nextFileIndex = fileDiffs.firstIndex(where: { $0.id == nextHeader.id }),
            nextFileIndex > 0
        else {
            return nil
        }
        return fileDiffs[nextFileIndex - 1]
    }

    func body(content: Content) -> some View {
        content
            .coordinateSpace(name: FileDiffStickyHeaderCoordinateSpace.name)
            .onPreferenceChange(FileDiffHeaderPositionKey.self) {
                headerPositions = $0.sorted { $0.minY < $1.minY }
                updateStickyFileDiff()
            }
            .onChange(of: fileDiffIDs) {
                updateStickyFileDiff()
            }
            .safeAreaBar(edge: .top, spacing: 0) {
                stickyHeaderView
            }
    }

    @ViewBuilder
    private var stickyHeaderView: some View {
        if let fileDiff = stickyFileDiff ?? fileDiffs.first {
            FileNameView(fileDiff: fileDiff)
                .font(Font.system(.body, design: .monospaced))
                .padding(.leading, FileDiffHeaderLayout.stickyFileNameLeadingPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(stickyFileDiff == nil ? 0 : 1)
                .allowsHitTesting(stickyFileDiff != nil)
        }
    }

    private func updateStickyFileDiff() {
        if let currentFileDiff {
            setStickyFileDiff(currentFileDiff)
        } else if isBeforeFirstHeader {
            setStickyFileDiff(nil)
        }
    }

    private var isBeforeFirstHeader: Bool {
        guard
            let firstHeader = headerPositions.first,
            let firstHeaderIndex = fileDiffs.firstIndex(where: { $0.id == firstHeader.id })
        else {
            return false
        }
        return firstHeaderIndex == 0 && firstHeader.minY > 0
    }

    private func setStickyFileDiff(_ fileDiff: FileDiff?) {
        guard stickyFileDiff?.id != fileDiff?.id else {
            return
        }
        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            stickyFileDiff = fileDiff
        }
    }
}

enum FileDiffHeaderLayout {
    static let contentLeadingPadding: CGFloat = 16
    static let headerLeadingPadding: CGFloat = 3
    static let chevronWidth: CGFloat = 16
    static let chevronSpacing: CGFloat = 4
    static let stickyFileNameLeadingPadding = contentLeadingPadding + headerFileNameLeadingPadding
    static let headerFileNameLeadingPadding = headerLeadingPadding + chevronWidth + chevronSpacing
}

extension View {
    func fileDiffStickyHeader(fileDiffs: [ExpandableModel<FileDiff>]) -> some View {
        modifier(FileDiffStickyHeaderModifier(fileDiffs: fileDiffs.map(\.model)))
    }

    func fileDiffHeaderPosition(id: String) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: FileDiffHeaderPositionKey.self,
                    value: [
                        FileDiffHeaderPosition(
                            id: id,
                            minY: proxy.frame(in: .named(FileDiffStickyHeaderCoordinateSpace.name)).minY
                        )
                    ]
                )
            }
        }
    }
}
