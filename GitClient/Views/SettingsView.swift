//
//  SettingsView.swift
//  GitClient
//
//  Settings window with update preferences.
//

import SwiftUI
@preconcurrency import Sparkle

struct SettingsView: View {
    let updater: SPUUpdater
    var checkForUpdatesViewModel: CheckForUpdatesViewModel

    var body: some View {
        Form {
            Section("Updates") {
                LabeledContent("Version \(versionString)") {
                    Button("Check for Updates…") {
                        checkForUpdatesViewModel.checkForUpdates()
                    }
                    .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
                }
                Toggle("Automatically check for updates", isOn: automaticallyChecksForUpdates)
                Toggle("Automatically download updates", isOn: automaticallyDownloadsUpdates)
            }
        }
        .formStyle(.grouped)
    }

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    private var automaticallyChecksForUpdates: Binding<Bool> {
        Binding(
            get: { updater.automaticallyChecksForUpdates },
            set: { updater.automaticallyChecksForUpdates = $0 }
        )
    }

    private var automaticallyDownloadsUpdates: Binding<Bool> {
        Binding(
            get: { updater.automaticallyDownloadsUpdates },
            set: { updater.automaticallyDownloadsUpdates = $0 }
        )
    }
}
