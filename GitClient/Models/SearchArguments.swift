//
//  SearchArguments.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/06/23.
//

import Foundation

struct SearchArguments {
    var revisionRange:[String] = []
    var grep: [String] = []
    var grepAllMatch = false
    var s = ""
    var g = ""
    var authors:[String] = []
    var paths: [String] = []
}
