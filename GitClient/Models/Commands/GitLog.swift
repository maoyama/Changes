//
//  GitLog.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import Foundation

struct GitLog: Git {
    typealias OutputModel = [Commit]
    var arguments: [String] {
        var args = [
            "git",
            "log",
            "--pretty=format:%H"
            + .formatSeparator + "%P"
            + .formatSeparator + "%an"
            + .formatSeparator + "%aE"
            + .formatSeparator + "%aI"
            + .formatSeparator + "%s"
            + .formatSeparator + "%b"
            + .formatSeparator + "%D"
            + .componentSeparator,
        ]
        args.append("--topo-order")

        if merges {
            args.append("--merges")
        }
        if ancestryPath {
            args.append("--ancestry-path")
        }
        if reverse {
            args.append("--reverse")
        }
        if number > 0 {
            args.append("-\(number)")
        }
        if skip > 0 {
            args.append("--skip=\(skip)")
        }
        args = args + grep.map { "--grep=\($0)" }
        if grepAllMatch {
            args.append("--all-match")
        }
        if !s.isEmpty {
            args.append("-S")
            args.append(s)
            args.append("--pickaxe-regex")
        }
        if !g.isEmpty {
            args.append("-G")
            args.append(g)
        }
        args = args + authors.map { "--author=\($0)" }
        if noWalk {
            args.append("--no-walk")
        }

        if !revisionRange.isEmpty {
            args = args + revisionRange
        }

        if !paths.isEmpty {
            args.append("--")
            args = args + paths
        }
        return args
    }
    var directory: URL
    var merges = false
    var ancestryPath = false
    var reverse = false
    var number = 0
    var skip = 0
    var grep: [String] = []
    var grepAllMatch = false
    var s = ""
    var g = ""
    var authors:[String] = []
    var noWalk = false
    var revisionRange: [String] = []
    var paths: [String] = []
    
    func parse(for stdOut: String) throws -> [Commit] {
        guard !stdOut.isEmpty else { return [] }
        let dropped = stdOut.dropLast(String.componentSeparator.count)
        let logs = dropped.components(separatedBy: String.componentSeparator + "\n")
        return logs.map { log in
            let separated = log.components(separatedBy: String.formatSeparator)
            let refs: [String]
            if separated[7].isEmpty {
                refs = []
            } else {
                refs = separated[7].components(separatedBy: ", ")
            }
            return Commit(
                hash: separated[0],
                parentHashes: separated[1].components(separatedBy: .whitespacesAndNewlines),
                author: separated[2],
                authorEmail: separated[3],
                authorDate: separated[4],
                title: separated[5],
                body: separated[6],
                branches: refs.filter { !$0.hasPrefix("tag: ") },
                tags: refs.filter { $0.hasPrefix("tag: ") }.map { String($0.dropFirst(5)) }
            )
        }
    }
}

