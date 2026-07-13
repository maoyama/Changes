//
//  GitClientApp.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/17.
//

import SwiftUI
@preconcurrency import Sparkle

@main
struct GitClientApp: App {
    @State private var expandAllFiles: UUID?
    @State private var collapseAllFiles: UUID?

    private let updaterController: SPUStandardUpdaterController
    @State private var checkForUpdatesViewModel: CheckForUpdatesViewModel

    init() {
        let controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        self.updaterController = controller
        self._checkForUpdatesViewModel = State(initialValue: CheckForUpdatesViewModel(updater: controller.updater))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.expandAllFiles, expandAllFiles)
                .environment(\.collapseAllFiles, collapseAllFiles)
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    checkForUpdatesViewModel.checkForUpdates()
                }
                .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
            }
            CommandGroup(before: .toolbar) {
                Button("Expand All Files") {
                    expandAllFiles = UUID()
                }
                .keyboardShortcut(.rightArrow, modifiers: .option)
                Button("Collapse All Files") {
                    collapseAllFiles = UUID()
                }
                .keyboardShortcut(.leftArrow, modifiers: .option)
                Divider()
            }
        }

        Window("Commit Message Snippets", id: WindowID.commitMessageSnippets.rawValue) {
            CommitMessageSnippetView()
        }

        Settings {
            SettingsView(updater: updaterController.updater, checkForUpdatesViewModel: checkForUpdatesViewModel)
        }
    }
}
