//
//  DiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/05/26.
//

import SwiftUI

struct UnstagedView: View {
    @Binding var fileDiffs: [ExpandableModel<FileDiff>]
    var status: String
    var untrackedFiles: [String]
    var onSelectFileDiff: ((FileDiff) -> Void)?
    var onSelectChunk: ((FileDiff, Chunk) -> Void)?
    var onSelectUntrackedFile: ((String) -> Void)?
    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if fileDiffs.isEmpty && untrackedFiles.isEmpty {
                LazyVStack(alignment: .center) {
                    Label("No Changes", systemImage: "plusminus")
                        .foregroundStyle(.secondary)
                        .padding()
                        .padding()
                        .padding(.bottom)
                        .padding(.trailing)
                }
            }
            StagedFileDiffView(
                expandableFileDiffs: $fileDiffs,
                selectButtonImageSystemName: "plus.circle",
                selectButtonHelp: "Stage This Hunk",
                onSelectFileDiff: onSelectFileDiff,
                onSelectChunk: onSelectChunk
            )
            .padding(.leading, 4)
            .padding(.top)

            if !untrackedFiles.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Untracked Files")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .padding(.top)
                    ForEach(untrackedFiles, id: \.self) { file in
                        HStack {
                            Text(file)
                                .fontWeight(.bold)
                            Spacer()
                            Button {
                                onSelectUntrackedFile?(file)
                            } label: {
                                Image(systemName: "plus.circle")
                            }
                            .buttonStyle(.plain)
                            .help("Stage This File")
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        } label: {
            SectionHeader(title: "Unstaged Changes", callout: status)
                .padding(.leading, 3)
        }
        .padding(.horizontal)
    }
}

#Preview {
    @Previewable @State var fileDiffs: [ExpandableModel<FileDiff>] = []

    let raw = """
    diff --git a/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved b/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
    index ca7d6df..b9d9984 100644
    --- a/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
    +++ b/GitBlamePR.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
    @@ -24,7 +24,7 @@
     "repositoryURL": "https://github.com/onevcat/Kingfisher.git",
     "state": {
       "branch": null,
    -          "revision": "7ccfb6cefdb6180cde839310e3dbd5b2d6fefee5",
    +          "revision": "20d21b3fd7192a42851d7951453e96b41e4e1ed1",
       "version": "5.13.3"
     }
    }
    diff --git a/GitBlamePR/View/DetailFooter.swift b/GitBlamePR/View/DetailFooter.swift
    index ec290b6..46b0c19 100644
    --- a/GitBlamePR/View/DetailFooter.swift
    +++ b/GitBlamePR/View/DetailFooter.swift
    @@ -6,6 +6,7 @@
    //  Copyright © 2020 dev.aoyama. All rights reserved。
    
    +// test
    import SwiftUI
    
    struct DetailFooter: View {
    @@ -36,6 +37,9 @@ struct DetailFooter: View {
    }
    }
    
    +
    +
    +// test2
    struct DetailFooter_Previews: PreviewProvider {
    static var previews: some View {
     Group {
    diff --git a/testfile6.txt b/testfile6.txt
    new file mode 100644
    index 0000000..e69de29
    """

    let diff = try! Diff(raw: raw)
    fileDiffs = diff.fileDiffs.map { ExpandableModel(isExpanded: true, model: $0) }

    return ScrollView {
        UnstagedView(
            fileDiffs: $fileDiffs,
            status: "1 file changes",
            untrackedFiles: ["Projects/Files/Path.swift", "Projects/Files/Path1.swift"],
            onSelectFileDiff: { f in
                print(f)
            },
            onSelectChunk: { f, c in
                print(f, c)
            },
            onSelectUntrackedFile: { f in
                print(f)
            }
        )
    }
}
