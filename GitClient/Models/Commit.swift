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
        authorDateRelative(relativeTo: .now)
    }
    func authorDateRelative(relativeTo now: Date) -> String {
        guard let date = try? Date(authorDate, strategy: .iso8601) else {
            return ""
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: now)
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
