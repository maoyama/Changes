import SwiftUI

struct CompareRevisionsView: View {
    var folder: Folder
    @Environment(\.dismiss) private var dismiss
    @State private var tab = 0
    @State private var branches: [Branch] = []
    @State private var remoteBranches: [Branch] = []
    @State private var tags: [String] = []
    @State private var selectedBranch: String?
    @State private var selectedTag: String?
    @State private var filterText = ""
    @State private var isLoading = true
    @State private var error: Error?

    private var filteredBranches: [Branch] {
        branches.filter { filterText.isEmpty || $0.name.localizedCaseInsensitiveContains(filterText) }
    }

    private var filteredRemoteBranches: [Branch] {
        remoteBranches.filter { filterText.isEmpty || $0.name.localizedCaseInsensitiveContains(filterText) }
    }

    private var filteredTags: [String] {
        tags.filter { filterText.isEmpty || $0.localizedCaseInsensitiveContains(filterText) }
    }

    private var selection: String? {
        if tab == 1 { return selectedTag }
        guard let selectedBranch else { return nil }
        if let branch = branches.first(where: { revision(for: $0) == selectedBranch }) {
            return branch.name
        }
        return remoteBranches.first { "refs/remotes/" + $0.name == selectedBranch }?.name
    }

    private var selectedRevision: String? {
        if tab == 1 { return selectedTag.map { "refs/tags/" + $0 } }
        return selectedBranch
    }

    private func revision(for branch: Branch) -> String {
        branch.isDetached ? "HEAD" : "refs/heads/" + branch.name
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
                        if !filteredBranches.isEmpty {
                            Section("Local") {
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
                                    .tag(revision(for: branch))
                                }
                            }
                        }
                        if !filteredRemoteBranches.isEmpty {
                            Section("Remotes") {
                                ForEach(filteredRemoteBranches) { branch in
                                    Label(branch.name, systemImage: "arrow.triangle.branch")
                                        .tag("refs/remotes/" + branch.name)
                                }
                            }
                        }
                    }
                    .overlay {
                        if filteredBranches.isEmpty && filteredRemoteBranches.isEmpty {
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
                selectedBranch = branches.current.map { revision(for: $0) }
                remoteBranches = try await Process.output(GitBranch(directory: folder.url, isRemote: true))
                    .filter { !$0.name.contains(" -> ") }
                tags = try await Process.output(GitTag(directory: folder.url))
            } catch {
                self.error = error
            }
        }
        .errorSheet($error)
    }
}
