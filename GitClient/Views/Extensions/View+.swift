//
//  View+.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import SwiftUI

extension View {
    func errorSheet(_ error: Binding<Error?>) -> some View {
        sheet(isPresented: .constant(error.wrappedValue != nil)) {
            ErrorTextSheet(error: error)
        }
    }

    func commitContextMenu(
        folder: URL,
        commit: Commit,
        logStore: LogStore,
        isRefresh: Binding<Bool>,
        showing: Binding<FolderViewShowing>,
        bindingError: Binding<Error?>
    ) -> some View {
        contextMenu{
            Button("Checkout") {
                Task {
                    do {
                        try await Process.output(GitCheckout(directory: folder, commitHash: commit.hash))
                        isRefresh.wrappedValue = true
                    } catch {
                        bindingError.wrappedValue = error
                    }
                }
            }
            Button("Revert" + (commit.parentHashes.count == 2 ? " -m 1 (mainline:  \(commit.parentHashes[0].prefix(7)))" : "")) {
                Task {
                    do {
                        if commit.parentHashes.count == 2 {
                            try await Process.output(GitRevert(directory: folder,  parentNumber: 1, commit: commit.hash))
                        } else {
                            try await Process.output(GitRevert(directory: folder, commit: commit.hash))
                        }
                        isRefresh.wrappedValue = true
                    } catch {
                        bindingError.wrappedValue = error
                    }
                }
            }
            if commit == logStore.commits.first {
                if let notCommitted = logStore.notCommitted {
                    if notCommitted.diffCached.isEmpty {
                        Button("Amend Commit with a New Message") {
                            showing.wrappedValue.amendCommitAt = commit
                        }
                    }
                } else {
                    Button("Amend Commit with a New Message") {
                        showing.wrappedValue.amendCommitAt = commit
                    }
                }
            }
            Button("Tag") {
                showing.wrappedValue.createNewTagAt = commit
            }
        }
    }

    func tapGesture(logID: String, selectionLogID: Binding<String?>, subSelectionLogID: Binding<String?>) -> some View {
        onTapGesture {
            if NSEvent.modifierFlags.contains(.command) {
                // Commandキーが押されている場合（複数選択や選択解除）
                if selectionLogID.wrappedValue != nil {
                    if selectionLogID.wrappedValue == logID && subSelectionLogID.wrappedValue == nil {
                        // 主選択が同じログIDで、副選択がない場合 → 選択解除
                        selectionLogID.wrappedValue = nil
                    } else if selectionLogID.wrappedValue == logID {
                        // 主選択が同じログIDで、副選択がある場合 → 副選択を主選択に昇格
                        selectionLogID.wrappedValue = subSelectionLogID.wrappedValue
                        subSelectionLogID.wrappedValue = nil
                    } else if subSelectionLogID.wrappedValue == logID {
                        // 副選択が同じログIDの場合 → 副選択を解除
                        subSelectionLogID.wrappedValue = nil
                    } else {
                        // 主選択・副選択どちらにも該当しない → 副選択に設定
                        subSelectionLogID.wrappedValue = logID
                    }
                } else {
                    // 主選択がまだない → 主選択として設定
                    selectionLogID.wrappedValue = logID
                }
            } else {
                // 通常クリック（Commandキーなし） → 主選択を設定し、副選択を解除
                selectionLogID.wrappedValue = logID
                subSelectionLogID.wrappedValue = nil
            }
        }
    }
}
