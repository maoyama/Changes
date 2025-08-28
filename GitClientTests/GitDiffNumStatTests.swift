//
//  GitDiffNumStatTests.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2024/09/07.
//

import XCTest
@testable import Changes

final class GitDiffNumStatTests: XCTestCase {
    func testParse() throws {
        let c = GitDiffNumStat(directory: URL(string: "file:///maoyama/Projects/")!)
        let stat = c.parse(for: """
3\t0\tJot/HistoryDetailNote.swift
0\t20\tJot/Note.swift
20\t0\tJot/Note.wift
3\t0\ttestfile5.swif
-\t-\ttestfile6.bin
""")
        XCTAssertEqual(
            stat.files,
            ["Jot/HistoryDetailNote.swift", "Jot/Note.swift", "Jot/Note.wift", "testfile5.swif", "testfile6.bin"]
        )
        XCTAssertEqual(
            stat.insertions,
            [3, 0, 20, 3, 0]
        )
        XCTAssertEqual(
            stat.deletions,
            [0, 20, 0, 0, 0]
        )
    }
}
