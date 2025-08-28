//
//  SearchTokensHandlerTests.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2025/04/03.
//

import Testing
@testable import Changes

struct SearchTokensHandlerTests {
    @Test func handleGrep() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grepAllMatch, text: "a")]
        let newTokens: [SearchToken] = [.init(kind: .grepAllMatch, text: "a"), .init(kind: .grep, text: "b")]
        let handledTokens = SearchTokensHandler.normalize(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens.first!.kind == .grep )
        #expect(handledTokens.last!.kind == .grep )
    }

    @Test func handleGrepInEdit() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grepAllMatch, text: "a"), .init(kind: .grepAllMatch, text: "b")]
        let newTokens: [SearchToken] = [.init(kind: .grep, text: "a"), .init(kind: .grepAllMatch, text: "b")]
        let handledTokens = SearchTokensHandler.normalize(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens.first!.kind == .grep )
        #expect(handledTokens.last!.kind == .grep )
    }

    @Test func handleGrepAllMath() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grep, text: "a")]
        let newTokens: [SearchToken] = [.init(kind: .grep, text: "a"), .init(kind: .grepAllMatch, text: "b")]
        let handledTokens = SearchTokensHandler.normalize(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens.first!.kind == .grepAllMatch )
        #expect(handledTokens.last!.kind == .grepAllMatch )
    }

    @Test func handleGrepAllMathInEdit() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grep, text: "a"), .init(kind: .grep, text: "b")]
        let newTokens: [SearchToken] = [.init(kind: .grep, text: "a"), .init(kind: .grepAllMatch, text: "b")]
        let handledTokens = SearchTokensHandler.normalize(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens.first!.kind == .grepAllMatch )
        #expect(handledTokens.last!.kind == .grepAllMatch )
    }

    @Test func handleS() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .g, text: "a")]
        let newTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .g, text: "a"), .init(kind: .s, text: "b"),]
        let handledTokens = SearchTokensHandler.normalize(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens.last!.kind == .s )
        #expect(handledTokens.count == 2 )
    }

    @Test func handleS2() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .s, text: "a")]
        let newTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .s, text: "a"), .init(kind: .s, text: "b"),]
        let handledTokens = SearchTokensHandler.normalize(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens == [.init(kind: .grep, text: "c"), .init(kind: .s, text: "b"),] )

    }

    @Test func handleSInEdit() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .g, text: "a"), .init(kind: .grep, text: "c")]
        let newTokens: [SearchToken] = [.init(kind: .s, text: "a"), .init(kind: .grep, text: "c")]
        let handledTokens = SearchTokensHandler.normalize(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens == newTokens )
    }

    @Test func handleG() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .s, text: "a")]
        let newTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .s, text: "a"), .init(kind: .g, text: "b")]
        let handledTokens = SearchTokensHandler.normalize(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens.last!.kind == .g )
        #expect(handledTokens.count == 2 )
    }

    @Test func handleG2() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .g, text: "a")]
        let newTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .g, text: "a"), .init(kind: .g, text: "b")]
        let handledTokens = SearchTokensHandler.normalize(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens == [.init(kind: .grep, text: "c"), .init(kind: .g, text: "b")])
    }

    @Test func handleGInEdit() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .s, text: "a"), .init(kind: .grep, text: "c")]
        let newTokens: [SearchToken] = [.init(kind: .g, text: "a"), .init(kind: .grep, text: "c")]
        let handledTokens = SearchTokensHandler.normalize(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens == newTokens )
    }

    @Test func handleAuthor() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .s, text: "a")]
        let newTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .s, text: "a"), .init(kind: .author, text: "a")]
        let handledTokens = SearchTokensHandler.normalize(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens == [.init(kind: .grep, text: "c"), .init(kind: .s, text: "a"), .init(kind: .author, text: "a")] )
    }

    @Test func handleAuthor2() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .author, text: "a")]
        let newTokens: [SearchToken] = [.init(kind: .grep, text: "c"), .init(kind: .author, text: "a"), .init(kind: .author, text: "b")]
        let handledTokens = SearchTokensHandler.normalize(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens == [.init(kind: .grep, text: "c"), .init(kind: .author, text: "a"), .init(kind: .author, text: "b")] )
    }

    @Test func handleAuhorInEdit() async throws {
        let oldTokens: [SearchToken] = [.init(kind: .author, text: "a"), .init(kind: .grep, text: "c")]
        let newTokens: [SearchToken] = [.init(kind: .author, text: "a"), .init(kind: .author, text: "c")]
        let handledTokens = SearchTokensHandler.normalize(oldTokens: oldTokens, newTokens: newTokens)
        #expect(handledTokens == [.init(kind: .author, text: "a"), .init(kind: .author, text: "c")] )
    }
}
