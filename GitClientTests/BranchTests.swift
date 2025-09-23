//
//  BranchTests.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2024/09/19.
//

import XCTest
@testable import Changes

final class BranchTests: XCTestCase {
    func testPoint() throws {
        let branch = Branch(name: "main", isCurrent: true)
        XCTAssertEqual(branch.point, "main")
    }

    func testPointForDetached() throws {
        let branch = Branch(name: "(HEAD detached at a036829)", isCurrent: true)
        XCTAssertEqual(branch.point, "a036829")
    }
}
