//
//  SystemLanguageModelService.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/06/17.
//

import Foundation
import FoundationModels

@Generable
struct GeneratedCommitMessage {
    @Guide(description: "The commit message")
    var commitMessage: String
}

@Generable
struct GeneratedDiffSummary {
    @Guide(description: "The summary of diff")
    var summary: String
}

@Generable
struct GeneratedStagingChanges {
    @Guide(description: "The hunk to stage list")
    var hunksToStage: [Bool]
}

@Generable
struct GeneratedCommitHashes {
    @Guide(description: "The commit hashes")
    var commitHashes: [String]
}

struct SystemLanguageModelService {
    var availability: SystemLanguageModel.Availability {
        SystemLanguageModel.default.availability
    }
    
    func commitMessage(stagedDiff: String) -> LanguageModelSession.ResponseStream<GeneratedCommitMessage> {
        let instructions = """
You are a good software engineer. When writing a commit message, it is not the initial commit.
The output format of git diff is as follows:
```
diff --git a/filename b/filename
index abc1234..def5678 100644
--- a/filename
+++ b/filename
@@ -start,count +start,count @@ optional context or function name
- line that was removed
+ line that was added
  unchanged line (context)
```
"""
        let prompt = "Generate a commit message in the imperative mood for the following changes: \(stagedDiff)"
        let session = LanguageModelSession(instructions: instructions)
        return session.streamResponse(to: prompt, generating: GeneratedCommitMessage.self)
    }

    func diffSummary(_ diff: String) -> LanguageModelSession.ResponseStream<GeneratedDiffSummary> {
        let instructions = """
You are a good software engineer.
The output format of git diff is as follows:
```
diff --git a/filename b/filename
index abc1234..def5678 100644
--- a/filename
+++ b/filename
@@ -start,count +start,count @@ optional context or function name
- line that was removed
+ line that was added
  unchanged line (context)
```
"""
        let prompt = "Generate a concise summary for the following changes in 200 characters or less: \(diff)"
        let session = LanguageModelSession(instructions: instructions)
        return session.streamResponse(to: prompt, generating: GeneratedDiffSummary.self)
    }

    /// Prefer commitMessage(stagedDiff: String)
    /// Using the tool didn’t particularly improve accuracy. I thought it would at least help organize the input information, though...
    func commitMessage(tools: [any Tool]) async throws -> String {
        let instructions = """
You are a good software engineer. When creating a commit message, it is not the initial commit.

The output format of git diff is as follows:
```
diff --git a/filename b/filename
index abc1234..def5678 100644
--- a/filename
+++ b/filename
@@ -start,count +start,count @@ optional context or function name
- line that was removed
+ line that was added
  unchanged line (context)
```
"""
        let prompt = "Please provide an appropriate commit message for staged changes"
        let session = LanguageModelSession(tools: tools, instructions: instructions)
        return try await session.respond(to: prompt, generating: GeneratedCommitMessage.self).content.commitMessage
    }
    
    /// beta
    func stagingChanges(unstagedDiff: String) async throws -> [Bool] {
        let instructions = """
You are a good software engineer. A hunk starts from @@ -start,count +start,count @@.
"""
        let prompt = "Please indicate which hunks should be committed by answering with booleans so that the response can be used as input for git add -p.: \(unstagedDiff)"
        let session = LanguageModelSession(instructions: instructions)
        return try await session.respond(to: prompt, generating: GeneratedStagingChanges.self, options: .init(temperature: 1.0)).content.hunksToStage
    }
    
    /// beta
    func stagingChanges(tools: [any Tool]) async throws -> [Bool] {
        let instructions = """
You are a good software engineer. A hunk starts from @@ -start,count +start,count @@.
"""
        let prompt = "Please indicate which unstaged changes should be committed by answering with booleans"
        let session = LanguageModelSession(tools: tools, instructions: instructions)
        return try await session.respond(to: prompt, generating: GeneratedStagingChanges.self, options: .init(temperature: 1.0)).content.hunksToStage
    }
    
    func commitHashes(_ searchArgment: SearchArguments, prompt: [String], directory: URL) async throws -> [String] {
        let instructions = """
            You are a good software engineer.
            """
        let prompt = "Please provide the commit hashes using git log for the following: \(prompt.joined(separator: "\n"))"
        let session = LanguageModelSession(tools: [GitLogTool(directory: directory, searchArguments: searchArgment)], instructions: instructions)
        return try await session.respond(to: prompt, generating: GeneratedCommitHashes.self).content.commitHashes
    }
}

@Generable
struct UncommitedChanges {
    @Guide(description: "The staged changes")
    var stagedChanges: [String]
    @Guide(description: "The unstaged changes")
    var unstagedChanges: [String]
}

struct UncommitedChangesTool: Tool {
    @Generable
    struct Arguments {}
    
    let name = "uncommitedChanges"
    let description: String = "Get a uncommitted changes"
    let directory: URL
    
    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        let gitDiff = try await Process.output(GitDiff(directory: directory))
        let gitDiffCached = try await Process.output(GitDiffCached(directory: directory))
        let diff = try Diff(raw: gitDiff).fileDiffs.map { $0.raw }
        let cachedDiff = try Diff(raw: gitDiffCached).fileDiffs.map { $0.raw }
        return  UncommitedChanges(stagedChanges: cachedDiff, unstagedChanges: diff)
    }
}

struct StagedChangesTool: Tool {
    @Generable
    struct Arguments {}
    
    let name = "stagedChanges"
    let description: String = "Get staged changes"
    let directory: URL
    
    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        let gitDiffCached = try await Process.output(GitDiffCached(directory: directory))
        let cachedDiff = try Diff(raw: gitDiffCached).fileDiffs.map { $0.raw }
        return cachedDiff
    }
}

struct UnstagedChangesTool: Tool {
    @Generable
    struct Arguments {}
    
    let name = "unstagedChanges"
    let description: String = "Get unstaged changes"
    let directory: URL
    
    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        let gitDiff = try await Process.output(GitDiff(directory: directory))
        let diff = try Diff(raw: gitDiff).fileDiffs.map { $0.raw }
        return diff
    }
}

struct GitLogTool: Tool {
    @Generable
    struct Arguments {
        @Guide(description: "Limit the number of commits to output", .range(1...100))
        var number: Int
        @Guide(description: "Skip number commits before starting to show the commit output")
        var skip: Int
    }

    @Generable
    struct GenerableCommit {
        init(_ commit: Commit) {
            self.hash = commit.hash
            self.parentHashes = commit.parentHashes
            self.author = commit.author
            self.authorEmail = commit.authorEmail
            self.authorDate = commit.authorDate
            self.title = commit.title
            self.body = commit.body
            self.branches = commit.branches
            self.tags = commit.tags
        }
        @Guide(description: "The commit hash")
        var hash: String
        var parentHashes: [String]
        var author: String
        var authorEmail: String
        @Guide(description: "The date the commit was created")
        var authorDate: String
        @Guide(description: "The commit message title")
        var title: String
        @Guide(description: "The commit message body")
        var body: String
        @Guide(description: "The branches referencing this commit")
        var branches: [String]
        @Guide(description: "The tags referencing this commit")
        var tags: [String]
    }

    let name = "gitLog"
    let description: String = "Get git commits"
    var directory: URL
    var searchArguments: SearchArguments

    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        let logs = try await Process.output(
            GitLog(directory: directory, number: arguments.number, skip: arguments.skip, grep: searchArguments.grep, grepAllMatch: searchArguments.grepAllMatch, s: searchArguments.s, g: searchArguments.g, authors: searchArguments.authors, revisionRange: searchArguments.revisionRange, paths: searchArguments.paths)
        )
        let commits = logs.map { GenerableCommit($0) }
        return commits
    }
}
