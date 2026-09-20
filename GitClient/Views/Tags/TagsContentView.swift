//
//  TagsContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/21.
//

import SwiftUI

struct TagsContentView: View {
    var folder: Folder
    @Binding var showingTags: Bool
    @Binding var tags: [String]?
    private var filteredTags: [String]? {
        guard !filterText.isEmpty else { return tags }
        return tags?.filter { $0.lowercased().contains(filterText.lowercased()) }
    }
    @State private var filterText: String = ""
    @State private var selection: String?
    @State private var error: Error?
    @State private var isFetching = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease")
                TextField(text: $filterText) {
                    Text("Filter")
                }
                if isFetching {
                    ProgressView()
                        .scaleEffect(0.4)
                        .frame(width: 29, height: 17)
                        .padding(.leading)
                } else {
                    Button {
                        isFetching = true
                        Task {
                            defer { isFetching = false }
                            do {
                                try await GitFetchExecutor.shared.execute(
                                    GitFetch(directory: folder.url, tags: true)
                                )
                                tags = try await Process.output(GitTag(directory: folder.url))
                            } catch {
                                self.error = error
                            }
                        }
                    } label: {
                        Label("Fetch Tags", systemImage: "arrow.down")
                            .labelStyle(.iconOnly)
                    }
                    .padding(.leading)
                    .help("Fetch Tags")
                }
            }
            .textFieldStyle(.roundedBorder)
            .padding()
            Divider()
            if let filteredTags {
                if filteredTags.isEmpty {
                    ScrollView {
                            Text("No Content")
                                .foregroundStyle(.secondary)
                                .padding()
                                .padding(.top, 220)
                    }
                } else {
                    List(filteredTags, id: \.self, selection: $selection) { tag in
                        Label(tag, systemImage: "tag")
                            .contextMenu {
                                Button("Delete") {
                                    Task {
                                        do {
                                            try await Process.output(GitTagDelete(directory: folder.url, tagname: tag))
                                            tags = tags?.filter{ $0 != tag}
                                        } catch {
                                            self.error = error
                                        }
                                    }
                                }
                            }
                    }
                    .onChange(of: selection ?? "", { _, newValue in
                        Task {
                            do {
                                try await Process.output(GitCheckout(directory: folder.url, commitHash: newValue))
                                showingTags = false
                            } catch {
                                self.error = error
                            }
                        }
                    })
                }
            }
        }
        .scrollContentBackground(.hidden)
        .errorSheet($error)
    }
}

#Preview {
    @Previewable @State var showingTags = false
    @Previewable @State var tags: [String]? = ["v1.0.0", "v1.1.0", "v2.0.0"]

    TagsContentView(folder: .init(url: URL(string: "file:///maoyama/Projects/")!), showingTags: $showingTags, tags: $tags)
        .frame(width: 300, height: 660)
}

#Preview("No Content") {
    @Previewable @State var showingTags = false
    @Previewable @State var tags: [String]? = []

    TagsContentView(folder: .init(url: URL(string: "file:///maoyama/Projects/")!), showingTags: $showingTags, tags: $tags)
        .frame(width: 300, height: 660)
}
