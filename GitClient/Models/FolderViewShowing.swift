//
//  FolderViewShowing.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/23.
//

import Foundation

struct FolderViewShowing {
    var branches = false
    var createNewBranchFrom: Branch?
    var renameBranch: Branch?
    var stashChanged = false
    var compareRevisions = false
    var tags = false
    var createNewTagAt: Commit?
    var amendCommitAt: Commit?
}
