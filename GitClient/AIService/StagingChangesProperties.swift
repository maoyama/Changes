//
//  StagingChangesProperties.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/29.
//

import Foundation

struct StagingChangesProperties: Codable {
    struct BooleanArray: Codable {
        struct Items: Codable {
            var type = "boolean"
        }
        var type = "array"
        var items = Items()
    }
    struct CommitMessage: Codable {
        var type = "string"
    }

    var hunksToStage = BooleanArray()
    var filesToStage = BooleanArray()
    var commitMessage = CommitMessage()
}

struct StagingChanges: Codable {
    var hunksToStage: [Bool]
    var filesToStage: [Bool]
    var commitMessage: String
}
