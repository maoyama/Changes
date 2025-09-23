//
//  LogStore.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/03.
//

import Foundation
import Observation

@MainActor
@Observable class LogStore {
    var number = 100
    var directory: URL?
    private var grep: [String] {
        searchTokens.filter { token in
            switch token.kind {
            case .grep, .grepAllMatch:
                return true
            default:
                return false
            }
        }.map { $0.text }
    }
    private var grepAllMatch: Bool {
        searchTokens.contains { $0.kind == .grepAllMatch }
    }
    private var s: String {
        searchTokens.filter { $0.kind == .s }.map { $0.text }.first ?? ""
    }
    private var g: String {
        searchTokens.filter { $0.kind == .g }.map { $0.text }.first ?? ""
    }
    private var authors: [String] {
        searchTokens.filter { $0.kind == .author }.map { $0.text }
    }
    private var searchTokenRevisionRange: [String] {
        searchTokens.filter { $0.kind == .revisionRange }.map { $0.text }
    }
    private var paths: [String] {
        searchTokens.filter { $0.kind == .path }.map { $0.text }
    }
//    private var promptForAI: [String] {
//        searchTokens.filter { $0.kind == .ai }.map { $0.text }
//    }
    private var searchArgments: SearchArguments {
        .init(
            revisionRange: searchTokenRevisionRange,
            grep: grep,
            grepAllMatch: grepAllMatch,
            s: s,
            g: g,
            authors: authors,
            paths: paths
        )
    }
    private var commitHashesByAI: [String] = []
    var searchTokens: [SearchToken] = []
    var commits: [Commit] = []
    var notCommitted: NotCommitted?
    var totalCommitsCount: Int? = nil
    var canLoadMore: Bool {
        guard let totalCommitsCount else { return false }
        return totalCommitsCount > commits.count
    }
    var error: Error?

    private func gitLog(directory: URL, number: Int=0, skip: Int=0) -> GitLog {
        if commitHashesByAI.isEmpty {
            return GitLog(
                directory: directory,
                number: number,
                skip: skip,
                grep: grep,
                grepAllMatch: grepAllMatch,
                s: s,
                g: g,
                authors: authors,
                revisionRange: searchTokenRevisionRange,
                paths: paths
            )
        } else {
            return GitLog(
                directory: directory,
                number: number,
                skip: skip,
                noWalk: true,
                revisionRange: commitHashesByAI
            )
        }
    }

    func logs() -> [Log] {
        var logs = commits.map { Log.committed($0) }
        if let notCommitted, !notCommitted.isEmpty {
            logs.insert(.notCommitted, at: 0)
        }
        return logs
    }

    /// 最新number件取得しlogsを差し替え
    func refresh() async {
        guard let directory else {
            notCommitted = nil
            commits = []
            commitHashesByAI = []
            return
        }
        do {
            commitHashesByAI = []
            notCommitted = try await notCommitted(directory: directory)
//            if !promptForAI.isEmpty {
//                if #available(macOS 26.0, *) {
//                    commitHashesByAI = try await SystemLanguageModelService().commitHashes(searchArgments, prompt: promptForAI , directory: directory)
//                }
//            }
            commits = try await Process.output(gitLog(directory: directory, number: number))
            try await loadTotalCommitsCount()
        } catch {
            self.error = error
        }
    }

    /// logsを全てを最新に更新しlogs.first以降のコミットを取得し追加
    func update() async {
        guard let directory else {
            notCommitted = nil
            commits = []
            return
        }

        do {
            notCommitted = try await notCommitted(directory: directory)
            commits = try await Process.output(gitLog(
                directory: directory,
                number: commits.count
            ))
            try await loadTotalCommitsCount()
        } catch {
            self.error = error
        }
    }

    func removeAll() {
        commits = []
        notCommitted = nil
        totalCommitsCount = nil
    }

    /// logビューの表示時に呼び出しし必要に応じてlogsを追加読み込み
    func logViewTask(_ log: Log) async {
        switch log {
        case .notCommitted:
            return
        case .committed(let commit):
            if commit == commits.last {
                await loadMore()
            }
        }
    }

    func nextLogID(logID: String) -> String? {
        if logID == Log.notCommitted.id {
            return commits.first?.id
        }
        let index = commits.firstIndex { $0.id == logID }
        guard let index, index + 1 < commits.count else { return nil }
        return commits[index + 1].id
    }

    func previousLogID(logID: String) -> String? {
        if logID == Log.notCommitted.id {
            return nil
        }
        let index = commits.firstIndex { $0.id == logID }
        guard let index else { return nil }
        if index == 0 {
            if let notCommitted, !notCommitted.isEmpty {
                return Log.notCommitted.id
            }
            return nil
        }
        return commits[index - 1].id
    }

    private func notCommitted(directory: URL) async throws -> NotCommitted {
        let gitDiff = try await Process.output(GitDiff(directory: directory))
        let gitDiffCached = try await Process.output(GitDiffCached(directory: directory))
        let status = try await Process.output(GitStatus(directory: directory))
        return NotCommitted(diff: gitDiff, diffCached: gitDiffCached, status: status)
    }
    /// logs.last以前のコミットを取得し追加
    func loadMore() async {
        guard let directory else { return }
        do {
            commits += try await Process.output(gitLog(
                directory: directory,
                number: number,
                skip: commits.count
            ))
        } catch {
            self.error = error
        }
    }

    private func loadTotalCommitsCount() async throws {
        guard let directory else { return }
        if searchTokens.isEmpty {
            totalCommitsCount = try await Process.output(GitRevListCount(directory: directory))
        } else {
            totalCommitsCount = try await Process.output(gitLog(
                directory: directory
            )).count
        }
    }
}
