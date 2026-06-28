//
//  GitShow.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/08.
//

import Foundation

struct GitShow: Git {
    typealias OutputModel = CommitDetail
    var arguments: [String] {
        [
            "git",
            "show",
            "--pretty=format:%H"
            + .formatSeparator + "%T"
            + .formatSeparator + "%P"
            + .formatSeparator + "%an"
            + .formatSeparator + "%aE"
            + .formatSeparator + "%aI"
            + .formatSeparator + "%s"
            + .formatSeparator + "%b"
            + .formatSeparator + "%D"
            + .componentSeparator,
            object
        ]
    }
    var directory: URL
    var object: String

    func parse(for stdOut: String) throws -> CommitDetail {
        guard !stdOut.isEmpty else { throw GenericError(errorDescription: "Parse error: stdOut is empty.") }
        let splits = stdOut.split(separator: String.componentSeparator + "\n", maxSplits: 1)
        let commitInfo = splits[0]
        let separated = commitInfo.components(separatedBy: String.formatSeparator)
        let refs: [String]
        if separated[8].isEmpty {
            refs = []
        } else {
            refs = separated[8].components(separatedBy: ", ")
        }
        let commit = Commit(
            hash: separated[0],
            treeHash: separated[1],
            parentHashes: separated[2].components(separatedBy: .whitespacesAndNewlines),
            author: separated[3],
            authorEmail: separated[4],
            authorDate: separated[5],
            title: separated[6],
            body: separated[7],
            branches: refs.filter { !$0.hasPrefix("tag: ") },
            tags: refs.filter { $0.hasPrefix("tag: ") }.map { String($0.dropFirst(5)) }
        )
        
        return CommitDetail(
            commit: commit,
            diff: try Diff(raw: String(splits[safe: 1] ?? ""))
        )
    }
}

