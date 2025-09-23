//
//  SerachTokensHandler.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/03.
//

struct SearchTokensHandler {
    static private func newToken(old: [SearchToken], new: [SearchToken]) -> SearchToken? {
        new.first { !old.contains($0) }
    }

    static func searchTokenHistory(currentHistory: [SearchToken], old: [SearchToken], new: [SearchToken]) -> [SearchToken] {
        guard let newToken = SearchTokensHandler.newToken(old: old, new: new) else { return currentHistory }
        var history = currentHistory
        history.removeAll { $0 == newToken }
        history.insert(newToken, at: 0)
        return Array(history.prefix(10))
    }

    static func normalize(oldTokens: [SearchToken], newTokens: [SearchToken]) -> [SearchToken] {
        if let newToken = newToken(old: oldTokens, new: newTokens) {
            switch newToken.kind {
            case .grep, .grepAllMatch:
                return newTokens.map { token in
                    switch token.kind {
                    case .grep, .grepAllMatch:
                        var updateToken = token
                        updateToken.kind = newToken.kind
                        return updateToken
                    default:
                        return token
                    }
                }
            case .s:
                return newTokens.filter { token in
                    switch token.kind {
                    case .s:
                        return token == newToken
                    case .g:
                        return false
                    default:
                        return true
                    }
                }
            case .g:
                return newTokens.filter { token in
                    switch token.kind {
                    case .g:
                        return token == newToken
                    case .s:
                        return false
                    default:
                        return true
                    }
                }
            case .revisionRange, .author, .path:
                return newTokens
//            case .ai:
//                return newTokens
            }
        } else {
            return newTokens
        }
    }
}
