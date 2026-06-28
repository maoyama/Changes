//
//  CheckForUpdatesViewModel.swift
//  GitClient
//
//  Created with Sparkle integration for auto-update support.
//

import Foundation
@preconcurrency import Sparkle
import Combine

@MainActor
@Observable final class CheckForUpdatesViewModel {
    var canCheckForUpdates = false

    private let updater: SPUUpdater
    private var cancellable: AnyCancellable?

    init(updater: SPUUpdater) {
        self.updater = updater
        cancellable = updater.publisher(for: \.canCheckForUpdates)
            .assign(to: \.canCheckForUpdates, on: self)
    }

    func checkForUpdates() {
        updater.checkForUpdates()
    }
}
