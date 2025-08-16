//
//  SystemLanguageModelServiceTests.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2025/06/17.
//

import Testing
@testable import Tempo
import FoundationModels
import Foundation

struct SystemLanguageModelServiceTests {
    
    @Test func commitMessage() async throws {
        let message = try await SystemLanguageModelService().commitMessage(stagedDiff: """
            diff --git a/GitClient/Views/Folder/CommitGraphView.swift b/GitClient/Views/Folder/CommitGraphView.swift
            index 5f79207..4660cf4 100644
            --- a/GitClient/Views/Folder/CommitGraphView.swift
            +++ b/GitClient/Views/Folder/CommitGraphView.swift
            @@ -51,7 +51,6 @@ struct CommitGraphView: View {
                             .padding(.bottom, 22)
                         }
                     }
            -        .background(Color(NSColor.textBackgroundColor))
                     .focusable()
                     .focusEffectDisabled()
                     .onMoveCommand { direction in
            """)
        print(message)
        #expect(!message.isEmpty)
        
        let message2 = try await SystemLanguageModelService().commitMessage(stagedDiff: """
            diff --git a/GitClient/Models/Observables/LogStore.swift b/GitClient/Models/Observables/LogStore.swift
            index 8a43562..226c84e 100644
            --- a/GitClient/Models/Observables/LogStore.swift
            +++ b/GitClient/Models/Observables/LogStore.swift
            @@ -147,6 +147,24 @@ import Observation
                     }
                 }
             
            +    func nextLogID(logID: String) -> String? {
            +        if logID == Log.notCommitted.id {
            +            return commits.first?.id
            +        }
            +        let commit = commits.first { $0.id == logID }
            +        guard let commit else { return nil }
            +        return commit.parentHashes.last
            +    }
            +
            +    func previousLogID(logID: String) -> String? {
            +        if logID == Log.notCommitted.id {
            +            return nil
            +        }
            +        let index = commits.firstIndex { $0.id == logID }
            +        guard let index, index != 0 else { return nil }
            +        return commits[index - 1].id
            +    }
            +
                 private func notCommited(directory: URL) async throws -> NotCommitted {
                     let gitDiff = try await Process.output(GitDiff(directory: directory))
                     let gitDiffCached = try await Process.output(GitDiffCached(directory: directory))
            """)
        print(message2)
        #expect(!message2.isEmpty)
    }

    @Test func commitMessageWithTool() async throws {
        let stagedDiffRaw = """
                    diff --git a/GitClient/Views/Folder/CommitGraphView.swift b/GitClient/Views/Folder/CommitGraphView.swift
                    index 5f79207..4660cf4 100644
                    --- a/GitClient/Views/Folder/CommitGraphView.swift
                    +++ b/GitClient/Views/Folder/CommitGraphView.swift
                    @@ -51,7 +51,6 @@ struct CommitGraphView: View {
                                     .padding(.bottom, 22)
                                 }
                             }
                    -        .background(Color(NSColor.textBackgroundColor))
                             .focusable()
                             .focusEffectDisabled()
                             .onMoveCommand { direction in
                    """
        let message = try await SystemLanguageModelService().commitMessage(tools: [UncommitedChangesStubTool(cachedDiffRaw: stagedDiffRaw, diffRaw: "")])
        print(message)
        #expect(!message.isEmpty)
        
        let stagedDiffRaw2 = """
            diff --git a/GitClient/Models/Observables/LogStore.swift b/GitClient/Models/Observables/LogStore.swift
            index 8a43562..226c84e 100644
            --- a/GitClient/Models/Observables/LogStore.swift
            +++ b/GitClient/Models/Observables/LogStore.swift
            @@ -147,6 +147,24 @@ import Observation
                     }
                 }
             
            +    func nextLogID(logID: String) -> String? {
            +        if logID == Log.notCommitted.id {
            +            return commits.first?.id
            +        }
            +        let commit = commits.first { $0.id == logID }
            +        guard let commit else { return nil }
            +        return commit.parentHashes.last
            +    }
            +
            +    func previousLogID(logID: String) -> String? {
            +        if logID == Log.notCommitted.id {
            +            return nil
            +        }
            +        let index = commits.firstIndex { $0.id == logID }
            +        guard let index, index != 0 else { return nil }
            +        return commits[index - 1].id
            +    }
            +
                 private func notCommited(directory: URL) async throws -> NotCommitted {
                     let gitDiff = try await Process.output(GitDiff(directory: directory))
                     let gitDiffCached = try await Process.output(GitDiffCached(directory: directory))
            """
        let message2 = try await SystemLanguageModelService().commitMessage(tools: [UncommitedChangesStubTool(cachedDiffRaw: stagedDiffRaw2, diffRaw: "")])
        print(message2)
        #expect(!message2.isEmpty)
    }
    
    @Test func commitMessageWithStagedChangesTool() async throws {
        let stagedDiffRaw = """
                    diff --git a/GitClient/Views/Folder/CommitGraphView.swift b/GitClient/Views/Folder/CommitGraphView.swift
                    index 5f79207..4660cf4 100644
                    --- a/GitClient/Views/Folder/CommitGraphView.swift
                    +++ b/GitClient/Views/Folder/CommitGraphView.swift
                    @@ -51,7 +51,6 @@ struct CommitGraphView: View {
                                     .padding(.bottom, 22)
                                 }
                             }
                    -        .background(Color(NSColor.textBackgroundColor))
                             .focusable()
                             .focusEffectDisabled()
                             .onMoveCommand { direction in
                    """
        let message = try await SystemLanguageModelService().commitMessage(tools: [StagedChangesToolStub(cachedDiffRaw: stagedDiffRaw)])
        print(message)
        #expect(!message.isEmpty)
        
        let stagedDiffRaw2 = """
            diff --git a/GitClient/Models/Observables/LogStore.swift b/GitClient/Models/Observables/LogStore.swift
            index 8a43562..226c84e 100644
            --- a/GitClient/Models/Observables/LogStore.swift
            +++ b/GitClient/Models/Observables/LogStore.swift
            @@ -147,6 +147,24 @@ import Observation
                     }
                 }
             
            +    func nextLogID(logID: String) -> String? {
            +        if logID == Log.notCommitted.id {
            +            return commits.first?.id
            +        }
            +        let commit = commits.first { $0.id == logID }
            +        guard let commit else { return nil }
            +        return commit.parentHashes.last
            +    }
            +
            +    func previousLogID(logID: String) -> String? {
            +        if logID == Log.notCommitted.id {
            +            return nil
            +        }
            +        let index = commits.firstIndex { $0.id == logID }
            +        guard let index, index != 0 else { return nil }
            +        return commits[index - 1].id
            +    }
            +
                 private func notCommited(directory: URL) async throws -> NotCommitted {
                     let gitDiff = try await Process.output(GitDiff(directory: directory))
                     let gitDiffCached = try await Process.output(GitDiffCached(directory: directory))
            """
        let message2 = try await SystemLanguageModelService().commitMessage(tools: [UncommitedChangesStubTool(cachedDiffRaw: stagedDiffRaw2, diffRaw: "")])
        print(message2)
        #expect(!message2.isEmpty)
    }
    
    @Test func stagingChanges() async throws {
        let hunksToStages = try await SystemLanguageModelService().stagingChanges(unstagedDiff: """
            diff --git a/GitClient/Views/Folder/CommitGraphView.swift b/GitClient/Views/Folder/CommitGraphView.swift
            index 5f79207..4660cf4 100644
            --- a/GitClient/Views/Folder/CommitGraphView.swift
            +++ b/GitClient/Views/Folder/CommitGraphView.swift
            @@ -51,7 +51,6 @@ struct CommitGraphView: View {
                             .padding(.bottom, 22)
                         }
                     }
            -        .background(Color(NSColor.textBackgroundColor))
                     .focusable()
                     .focusEffectDisabled()
                     .onMoveCommand { direction in
            """)
        print(hunksToStages)
        #expect(!hunksToStages.isEmpty)
    }
    
    @Test func stagingChangesWithTool() async throws {
        let hunksToStages = try await SystemLanguageModelService().stagingChanges(tools: [UnstagedChangesToolStub(diffRaw: """
            diff --git a/GitClient/Views/Folder/CommitGraphView.swift b/GitClient/Views/Folder/CommitGraphView.swift
            index 5f79207..4660cf4 100644
            --- a/GitClient/Views/Folder/CommitGraphView.swift
            +++ b/GitClient/Views/Folder/CommitGraphView.swift
            @@ -51,7 +51,6 @@ struct CommitGraphView: View {
                             .padding(.bottom, 22)
                         }
                     }
            -        .background(Color(NSColor.textBackgroundColor))
                     .focusable()
                     .focusEffectDisabled()
                     .onMoveCommand { direction in
            """)])
        print(hunksToStages)
    }
    
    @Test func commitHashes() async throws {
        let commitHashes = try await SystemLanguageModelService().commitHashes(
            SearchArguments(),
            prompt: ["Commits which updated README.md"],
            directory: .testFixture!
        )
        print(commitHashes)
    }
    
    @Test func commitHashes2() async throws {
        let commitHashes = try await SystemLanguageModelService().commitHashes(
            SearchArguments(),
            prompt: ["最近行ったテストコードの変更のコミット"],
            directory: .testFixture!
        )
        print(commitHashes)
    }
}


struct UncommitedChangesStubTool: Tool {
    @Generable
    struct Arguments {}
    
    let name = UncommitedChangesTool(directory: .testFixture!).name
    let description: String = UncommitedChangesTool(directory: .testFixture!).description
    let cachedDiffRaw: String
    let diffRaw: String
    
    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        let diff = try Diff(raw: diffRaw).fileDiffs.map { $0.raw }
        let cachedDiff = try Diff(raw: cachedDiffRaw).fileDiffs.map { $0.raw }
        return UncommitedChanges(stagedChanges: cachedDiff, unstagedChanges: diff)
    }
}

struct StagedChangesToolStub: Tool {
    @Generable
    struct Arguments {}
    
    let name = StagedChangesTool(directory: .testFixture!).name
    let description: String = StagedChangesTool(directory: .testFixture!).description
    let cachedDiffRaw: String
    
    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        let cachedDiff = try Diff(raw: cachedDiffRaw).fileDiffs.map { $0.raw }
        return cachedDiff
    }
}

struct UnstagedChangesToolStub: Tool {
    @Generable
    struct Arguments {}
    
    let name = UnstagedChangesTool(directory: .testFixture!).name
    let description: String = UnstagedChangesTool(directory: .testFixture!).description
    let diffRaw: String
    
    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        let diff = try Diff(raw: diffRaw).fileDiffs.map { $0.raw }
        return diff
    }
}
