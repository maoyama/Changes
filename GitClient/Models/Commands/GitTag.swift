//
//  GitTag.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/21.
//

import Foundation

struct GitTag: Git {
    typealias OutputModel = [String]
    var arguments: [String] {
        [
            "git",
            "tag",
            "--no-column",
            "--sort=-creatordate",
        ]
    }
    var directory: URL

    func parse(for stdOut: String) throws -> [String] {
        stdOut.components(separatedBy: .newlines).dropLast()
    }
}
