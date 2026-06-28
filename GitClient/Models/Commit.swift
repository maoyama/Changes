//
//  Commit.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/18.
//

import Foundation

struct Commit: Hashable, Identifiable {
    var id: String { hash }
    var hash: String
    var treeHash: String
    var parentHashes: [String]
    var author: String
    var authorEmail: String
    var authorDate: String
    var authorDateDisplay: String {
        guard let date = try? Date(authorDate, strategy: .iso8601) else {
            return ""
        }
        return DateFormatter.localizedString(from: date, dateStyle: .long, timeStyle: .long)
    }
    var authorDateDisplayShort: String {
        guard let date = try? Date(authorDate, strategy: .iso8601) else {
            return ""
        }
        return DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
    }
    var authorDateRelative: String {
        guard let date = try? Date(authorDate, strategy: .iso8601) else {
            return ""
        }
        return date.formatted(.relative(presentation: .named))
    }
    var authorDateMedium: String {
        guard let date = ISO8601DateFormatter().date(from: authorDate) else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM, yyyy, HH:mm"
        return formatter.string(from: date)
    }
    var title: String
    var body: String
    var rawBody: String {
        guard !body.isEmpty else {
            return title
        }
        return title + "\n\n" + body
    }
    var branches: [String]
    var tags: [String]
}
