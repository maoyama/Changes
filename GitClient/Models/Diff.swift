//
//  CombinedDiff.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/04/07.
//

import Foundation

struct Diff: Hashable {
    var fileDiffs: [FileDiff]
    var raw: String

    init(raw: String) throws {
        self.raw = raw
        guard !raw.isEmpty else {
            fileDiffs = []
            return
        }
        fileDiffs = try ("\n" + raw).split(separator: "\ndiff").filter { !$0.hasPrefix("\n* Unmerged path") }.map { fileDiffRaw in
            let fileDiff = try FileDiff(raw: String("diff" + fileDiffRaw))
            return fileDiff
        }
    }

    func updateAll(stage: Bool) -> Self {
        let newFileDiffs = fileDiffs.map { fileDiff in
            fileDiff.updateAll(stage: stage)
        }
        var new = self
        new.fileDiffs = newFileDiffs
        return new
    }

    func updateFileDiffStage(_ fileDiff: FileDiff, stage: Bool) -> Self {
        let fileDiffIndex = fileDiffs.firstIndex { $0.id == fileDiff.id }
        guard let fileDiffIndex  else { return self }
        var new = self
        new.fileDiffs[fileDiffIndex] = fileDiff.updateAll(stage: stage)
        return new
    }

    func updateChunkStage(_ chunk: Chunk, in fileDiff: FileDiff, stage: Bool) -> Self {
        let fileDiffIndex = fileDiffs.firstIndex { $0.id == fileDiff.id }
        guard let fileDiffIndex  else { return self }
        let chunkIndex = fileDiffs[fileDiffIndex].chunks.firstIndex { $0.id == chunk.id }
        guard let chunkIndex else { return self }
        var new = self
        var newChunk = chunk
        newChunk.stage = stage
        new.fileDiffs[fileDiffIndex].chunks[chunkIndex] = newChunk
        return new
    }

    func stageStrings() -> [String] {
        Array(fileDiffs.map { $0.stageStrings() }.joined())
    }

    func unstageStrings() -> [String] {
        Array(fileDiffs.map { $0.unstageStrings() }.joined())
    }
}

struct FileDiff: Identifiable, Hashable {
    var id: String { raw }
    var header: String

    var fromFilePath: String {
        let components = header.components(separatedBy: " ")
        if components.count <= 2 {
            return ""
        }
        if components.count == 3 {
            return String(components[2])
        }
        let filePath = components[2].dropFirst(2) // Drop "a/" or "b/"
        return String(filePath)
    }

    var toFilePath: String {
        let components = header.components(separatedBy: " ")
        if components.count <= 2 {
            return ""
        }
        if components.count == 3 {
            return String(components[2])
        }
        let filePath = components[3].dropFirst(2) // Drop "a/" or "b/"
        return String(filePath)
    }

    var filePathDisplay: String {
        if fromFilePath == toFilePath {
            return fromFilePath
        }
        if !fromFilePath.isEmpty && !toFilePath.isEmpty && fromFilePath != toFilePath {
            return fromFilePath + " => " + toFilePath
        }
        return ""
    }

    var extendedHeaderLines: [String]
    var fromFileToFileLines: [String]
    var chunks: [Chunk]
    var stage: Bool?
    var stageString: String {
        if let stage, stage {
            return "y"
        }
        return "n"
    }
    var unstageString: String {
        if let stage, !stage {
            return "y"
        }
        return "n"
    }
    var raw: String

    private static func extractChunks(from lines: [String]) -> [String] {
        var chunks: [String] = []
        var currentChunk: String?

        for line in lines {
            if line.starts(with: "@@") {
                if let hunk = currentChunk {
                    chunks.append(hunk)
                }
                currentChunk = line
            } else {
                currentChunk?.append("\n" + line)
            }
        }

        if let lastHunk = currentChunk {
            chunks.append(lastHunk)
        }

        return chunks
    }

    init(raw: String) throws {
        self.raw = raw
        let splited = raw.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        let firstLine = splited.first
        guard let firstLine else {
            throw GenericError(errorDescription: "Parse error for first line in FileDiff")
        }
        header = firstLine
        let fromFileIndex = splited.firstIndex { $0.hasPrefix("--- ") }
        guard let fromFileIndex else {
            extendedHeaderLines = splited[1..<splited.endIndex].map { String($0) }
            fromFileToFileLines = []
            chunks = []
            return
        }
        extendedHeaderLines = splited[1..<fromFileIndex].map { String($0) }
        let toFileIndex = splited.lastIndex { $0.hasPrefix("+++ ") }
        guard let toFileIndex else {
            throw GenericError(errorDescription: "Parse error for toFileIndex in FileDiff")
        }
        fromFileToFileLines = splited[fromFileIndex...toFileIndex].map { String($0) }
        chunks = Self.extractChunks(from: splited).map { Chunk(raw: $0) }
    }

    func updateAll(stage: Bool) -> Self {
        guard !chunks.isEmpty else {
            var newSelf = self
            newSelf.stage = stage
            return newSelf
        }
        let newChunks = chunks.map { chunk in
            var newChunk = chunk
            newChunk.stage = stage
            return newChunk
        }
        var new = self
        new.chunks = newChunks
        return new
    }

    func stageStrings() -> [String] {
        guard !chunks.isEmpty else {
            return [stageString]
        }
        return chunks.map { $0.stageString }
    }

    func unstageStrings() -> [String] {
        guard !chunks.isEmpty else {
            return [unstageString]
        }
        return chunks.map { $0.unstageString }
    }
}

struct Chunk: Identifiable, Hashable {
    struct Line: Identifiable, Hashable {
        enum Kind {
            case removed, added, unchanged, header
        }
        var id: Int
        var kind: Kind {
            switch raw.first {
            case "-":
                return .removed
            case "+":
                return .added
            case " ":
                return .unchanged
            case "@":
                return .header
            default:
                return .unchanged
            }
        }
        var toFileLineNumber: Int?
        var raw: String

        init(id: Int, raw: String) {
            self.id = id
            self.raw = raw
        }
    }
    var id: String { raw }
    var lines: [Line]
    var lineNumbers: [String]
    var raw: String
    var stage: Bool?
    var stageString: String {
        if let stage, stage {
            return "y"
        }
        return "n"
    }
    var unstageString: String {
        if let stage, !stage {
            return "y"
        }
        return "n"
    }

    init(raw: String) {
        let toFileRange = raw.split(separator: "+", maxSplits: 1)[safe: 1]?.split(separator: " ", maxSplits: 1)[safe: 0]
        let splitedRange = toFileRange?.split(separator: ",", maxSplits: 1)
        let startLine = splitedRange?[safe: 0].map { String($0) }
        var currnetLine = startLine.map{ Int($0) } ?? nil

        self.raw = raw
        self.lines = raw.split(separator: "\n").enumerated().map {
            var line = Line(id: $0.offset, raw: String($0.element))
            switch line.kind {
            case .removed:
                break
            case .added:
                if let currnetLine1 = currnetLine {
                    line.toFileLineNumber = currnetLine1
                    currnetLine = currnetLine! + 1
                }
            case .unchanged:
                if let currnetLine1 = currnetLine {
                    line.toFileLineNumber = currnetLine1
                    currnetLine = currnetLine! + 1
                }
            case .header:
                break
            }
            return line
        }
        self.lineNumbers = lines.map({ line in
            if let toFileLineNumber = line.toFileLineNumber {
                return "\(toFileLineNumber)"
            }
            return ""
        })
    }
}
