//
//  SearchKind.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/02.
//

import Foundation

enum SearchKind: Codable, CaseIterable {
    case grep, grepAllMatch, g, s, author, revisionRange, path //, ai

    var label: String {
        switch self {
        case .grep:
            return "Message"
        case .grepAllMatch:
            return "Message(All Match)"
        case .g:
            return "Changed"
        case .s:
            return "Changed(Occurrences)"
        case .author:
            return "Author"
        case .revisionRange:
            return "Revision Range"
        case .path:
            return "Path"
//        case .ai:
//            return "AI"
        }
    }

    var shortLabel: String {
        switch self {
        case .grep:
            return "Message"
        case .grepAllMatch:
            return "Message(A)"
        case .g:
            return "Changed"
        case .s:
            return "Changed(O)"
        case .author:
            return "Author"
        case .revisionRange:
            return "Revision Range"
        case .path:
            return "Path"
//        case .ai:
//            return "AI"
        }
    }

    var help: String {
        switch self {
        case .grep:
            return "Search log messages matching the given pattern (regular expression)."
        case .grepAllMatch:
            return "Search log messages matching all given patterns instead of at least one."
        case .g:
            return "Search commits with added/removed lines that match the specified regex. "
        case .s:
            return "Search commits where the number of occurrences of the specified regex has changed (added/removed)."
        case .author:
            return "Search commits by author matching the given pattern (regular expression)."
        case .revisionRange:
            return "Search commits within the revision range specified by Git syntax. e.g., main.., v1.0.0...v2.0.0"
        case .path:
            return "Search commits that modify the specified file or directory path."
//        case .ai:
//            return "Search commits based on natural language input, powered by AI."
        }
    }
}
