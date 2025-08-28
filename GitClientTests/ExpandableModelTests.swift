//
//  ExpandableModelTests.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2025/05/10.
//

import Testing
@testable import Changes

struct ExpandableModelTests {

    struct Dummy: Hashable {
        let id: Int
        let name: String
    }

    @Test
    func testPreservesExpansionState() {
        let old: [ExpandableModel<Dummy>] = [
            ExpandableModel(isExpanded: false, model: Dummy(id: 1, name: "one")),
            ExpandableModel(isExpanded: false, model: Dummy(id: 2, name: "two"))
        ]
        let new: [Dummy] = [
            Dummy(id: 1, name: "one"),
            Dummy(id: 3, name: "three")
        ]

        let result = new.withExpansionState(from: old)

        #expect(result.count == 2)
        #expect(result[0].model == Dummy(id: 1, name: "one"))
        #expect(result[0].isExpanded == false)
        #expect(result[1].model == Dummy(id: 3, name: "three"))
        #expect(result[1].isExpanded == true) // default
    }

    @Test
    func testAllNewModelsDefaultToExpanded() {
        let old: [ExpandableModel<Dummy>] = []
        let new: [Dummy] = [
            Dummy(id: 10, name: "ten"),
            Dummy(id: 20, name: "twenty")
        ]

        let result = new.withExpansionState(from: old)

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.isExpanded })
    }

    @Test
    func testEmptyUpdateReturnsEmpty() {
        let old: [ExpandableModel<Dummy>] = [
            ExpandableModel(isExpanded: true, model: Dummy(id: 1, name: "one"))
        ]
        let new: [Dummy] = []

        let result = new.withExpansionState(from: old)
        #expect(result.isEmpty)
    }
}
