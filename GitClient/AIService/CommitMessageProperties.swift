//
//  CommitMessageProperties.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/29.
//

import Foundation

struct CommitMessageProperties: Codable {
    struct CommitMessage: Codable {
        var type = "string"
    }
    var commitMessage = CommitMessage()
}

struct GeneratedCommiMessage: Codable {
    var commitMessage: String
}
