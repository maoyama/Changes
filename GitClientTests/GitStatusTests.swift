//
//  GitStatusTests.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2025/06/06.
//

import Testing
@testable import Changes
import Foundation

struct GitStatusTests {

    @Test func parse() async throws {
        let git = GitStatus(directory: URL(string: "file:///hoge")!)
        let status = git.parse(for: """
UU Examples/Examples/ContentView.swift
UU README.md
M  Sources/SyntaxHighlight/Text+Init.swift
?? Sources/SyntaxHighlight/Hoge+Init.swift
""")
        #expect(status.unmergedFiles == ["Examples/Examples/ContentView.swift", "README.md"])
        #expect(status.untrackedFiles == ["Sources/SyntaxHighlight/Hoge+Init.swift"])
    }

}
