import Foundation

struct GitRef: Hashable, Identifiable {
    enum Kind: Hashable {
        case head
        case localBranch
        case remoteBranch
        case tag
    }

    var name: String
    var kind: Kind

    var id: String {
        revision
    }

    var revision: String {
        switch kind {
        case .head:
            "HEAD"
        case .localBranch:
            "refs/heads/\(name)"
        case .remoteBranch:
            "refs/remotes/\(name)"
        case .tag:
            "refs/tags/\(name)"
        }
    }

    var systemImage: String {
        kind == .tag ? "tag" : "arrow.triangle.branch"
    }
}
