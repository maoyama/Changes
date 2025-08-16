//
//  EnviromentValues+.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/29.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var folder: URL?
    @Entry var expandAllFiles: UUID?
    @Entry var collapseAllFiles: UUID?
}
