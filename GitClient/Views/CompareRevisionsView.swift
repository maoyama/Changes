import SwiftUI

struct CompareRevisionsView: View {
    var folder: Folder
    @Environment(\.dismiss) private var dismiss
    @State private var tab = 0
    @State private var branches: [Branch] = []
    @State private var tags: [String] = []
    @State private var selectedBranch: String?
    @State private var selectedTag: String?
    @State private var filterText = ""
    @State private var isLoading = true
    @State private var error: Error?

    private var filteredBranches: [Branch] {
        branches.filter { filterText.isEmpty || $0.name.localizedCaseInsensitiveContains(filterText) }
    }

    private var filteredTags: [String] {
        tags.filter { filterText.isEmpty || $0.localizedCaseInsensitiveContains(filterText) }
    }

    private var selection: String? {
        tab == 0 ? selectedBranch : selectedTag
    }

    private var selectedRevision: String? {
        guard let selection else { return nil }
        if tab == 1 { return "refs/tags/" + selection }
        if branches.first(where: { $0.name == selection })?.isDetached == true {
            return "HEAD"
        }
        return "refs/heads/" + selection
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                Picker("References", selection: $tab) {
                    Text("Branches").tag(0)
                    Text("Tags").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease")
                    TextField("Filter", text: $filterText)
                        .textFieldStyle(.roundedBorder)
                }
                .padding([.horizontal, .bottom])

                Divider()

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if tab == 0 {
                    List(selection: $selectedBranch) {
                        ForEach(filteredBranches) { branch in
                            HStack {
                                Label(branch.name, systemImage: "arrow.triangle.branch")
                                Spacer()
                                if branch.isCurrent {
                                    Text("Current")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tag(branch.name)
                        }
                    }
                    .overlay {
                        if filteredBranches.isEmpty {
                            Text(filterText.isEmpty ? "No Branches" : "No Results")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    List(filteredTags, id: \.self, selection: $selectedTag) { tag in
                        Label(tag, systemImage: "tag")
                            .tag(tag)
                    }
                    .overlay {
                        if filteredTags.isEmpty {
                            Text(filterText.isEmpty ? "No Tags" : "No Results")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
        } detail: {
            Group {
                if let selection, let selectedRevision {
                    CommitDiffView(
                        selectionLogID: "HEAD",
                        subSelectionLogID: selectedRevision,
                        selectionTitle: branches.current.map { $0.isDetached ? "HEAD" : $0.name } ?? "HEAD",
                        subSelectionTitle: selection
                    )
                    .environment(\.folder, folder.url)
                } else {
                    Text(tab == 0 ? "Select a Branch" : "Select a Tag")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaBar(edge: .bottom) {
                HStack {
                    Spacer()
                    Button("Close") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
                .padding()
            }
        }
        .frame(width: 800, height: 700)
        .task {
            defer { isLoading = false }
            do {
                branches = try await Process.output(GitBranch(directory: folder.url))
                selectedBranch = branches.current?.name
                tags = try await Process.output(GitTag(directory: folder.url))
            } catch {
                self.error = error
            }
        }
        .errorSheet($error)
    }
}
