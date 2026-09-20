//
//  GitFetch.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/18.
//

import Foundation

struct GitFetch: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        var arguments = ["git", "fetch"]
        if tags {
            arguments.append("--tags")
        }
        return arguments
    }
    var directory: URL
    var tags = false

    func parse(for stdOut: String) -> Void {}
}
