//
//  FolderTests.swift
//  GitClientTests
//

import Foundation
import Testing
@testable import Changes

struct FolderTests {

    @Test
    func encodeDecodePreservesFolderOrder() throws {
        let urls = [
            URL(fileURLWithPath: "/projects/alpha"),
            URL(fileURLWithPath: "/projects/beta"),
            URL(fileURLWithPath: "/projects/gamma"),
        ]
        let folders = urls.map { Folder(url: $0) }

        let data = try JSONEncoder().encode(folders)
        let decoded = try JSONDecoder().decode([Folder].self, from: data)

        #expect(decoded.map(\.url) == urls)
    }

    @Test
    func moveThenEncodeDecodePreservesReorderedFolders() throws {
        let urls = [
            URL(fileURLWithPath: "/projects/alpha"),
            URL(fileURLWithPath: "/projects/beta"),
            URL(fileURLWithPath: "/projects/gamma"),
        ]
        var folders = urls.map { Folder(url: $0) }
        folders.move(fromOffsets: IndexSet(integer: 2), toOffset: 0)

        let data = try JSONEncoder().encode(folders)
        let decoded = try JSONDecoder().decode([Folder].self, from: data)

        #expect(decoded.map(\.url) == [urls[2], urls[0], urls[1]])
    }
}
