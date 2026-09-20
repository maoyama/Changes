import SwiftUI

struct CompareRevisionsView: View {
    private enum ComparisonSide {
        case base, compare
    }

    var folder: Folder
    @Environment(\.dismiss) private var dismiss
    @State private var tab = 0
    @State private var branches: [Branch] = []
    @State private var remoteBranches: [Branch] = []
    @State private var tags: [String] = []
    @State private var baseRevision = "HEAD"
    @State private var compareRevision: String?
    @State private var editingSide: ComparisonSide = .compare
    @State private var filterText = ""
    @State private var isLoading = true
    @State private var isFetching = false
    @State private var diffRefreshID = UUID()
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

    private var editingRevision: String? {
        editingSide == .base ? baseRevision : compareRevision
    }

    private var listSelection: Binding<String?> {
        Binding {
            guard let reference = editingRevision,
                  reference.hasPrefix("refs/tags/") == (tab == 1) else { return nil }
            return reference
        } set: { reference in
            guard let reference else { return }
            if editingSide == .base {
                baseRevision = reference
            } else {
                compareRevision = reference
            }
        }
    }

    private func revision(for branch: Branch) -> String {
        branch.isDetached ? "HEAD" : "refs/heads/" + branch.name
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                Text("Compare")
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.horizontal, .top])
                comparisonControls
                Divider()
                HStack {
                    Picker("References", selection: $tab) {
                        Text("Branches").tag(0)
                        Text("Tags").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    if isFetching {
                        ProgressView()
                            .scaleEffect(0.4)
                            .frame(width: 29, height: 17)
                    } else {
                        Button {
                            isFetching = true
                            Task {
                                defer { isFetching = false }
                                do {
                                    try await GitFetchExecutor.shared.execute(
                                        GitFetch(directory: folder.url, tags: true)
                                    )
                                    try await loadReferences()
                                    diffRefreshID = UUID()
                                } catch {
                                    self.error = error
                                }
                            }
                        } label: {
                            Label("Fetch Branches and Tags", systemImage: "arrow.down")
                                .labelStyle(.iconOnly)
                        }
                        .help("Fetch Branches and Tags")
                        .disabled(isLoading)
                    }
                }
                .padding()

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if tab == 0 {
                    List(selection: listSelection) {
                        if !filteredBranches.isEmpty {
                            Section("Local") {
                                ForEach(filteredBranches) { branch in
                                    HStack {
                                        referenceRow(branch.name, systemImage: "arrow.triangle.branch")
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
                                    referenceRow(branch.name, systemImage: "arrow.triangle.branch")
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
                    List(filteredTags, id: \.self, selection: listSelection) { tag in
                        referenceRow(tag, systemImage: "tag")
                        .tag("refs/tags/" + tag)
                    }
                    .overlay {
                        if filteredTags.isEmpty {
                            Text(filterText.isEmpty ? "No Tags" : "No Results")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .safeAreaBar(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease")
                        TextField("Filter", text: $filterText)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
        } detail: {
            Group {
                if let compareRevision {
                    CommitDiffView(
                        selectionLogID: baseRevision,
                        subSelectionLogID: compareRevision,
                        selectionTitle: referenceName(baseRevision),
                        subSelectionTitle: referenceName(compareRevision),
                        showsComparisonControls: false
                    )
                    .environment(\.folder, folder.url)
                    .id(diffRefreshID)
                } else {
                    Text("Select a branch or tag for Compare")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaBar(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
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
        }
        .frame(width: 800, height: 700)
        .task {
            defer { isLoading = false }
            do {
                try await loadReferences()
                baseRevision = branches.current.map { revision(for: $0) } ?? "HEAD"
            } catch {
                self.error = error
            }
        }
        .errorSheet($error)
    }

    private func referenceRow(_ name: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 13))
                .foregroundStyle(Color.accentColor)
                .frame(width: 16)
                .accessibilityHidden(true)
            Text(name)
        }
        .accessibilityElement(children: .combine)
    }

    private var comparisonControls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                comparisonSideButton(.base, title: "Base", reference: baseRevision)
                Button(action: swapComparison) {
                    Label("Swap the Comparison", systemImage: "arrow.up.arrow.down")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                .help("Swap the Comparison")
                .disabled(compareRevision == nil || isLoading)
            }
            comparisonSideButton(.compare, title: "Compare", reference: compareRevision)
        }
        .padding(10)
    }

    private func comparisonSideButton(_ side: ComparisonSide, title: String, reference: String?) -> some View {
        Button {
            editingSide = side
            revealEditingRevision()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let reference {
                        referenceRow(
                            referenceName(reference),
                            systemImage: reference.hasPrefix("refs/tags/") ? "tag" : "arrow.triangle.branch"
                        )
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text("No Selection")
                            .foregroundStyle(.secondary)
                            .padding(.leading, 22)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(editingSide == side ? Color.accentColor.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(editingSide == side ? [.isSelected] : [])
        .help(reference.map { referenceName($0) + "\nSelect a branch or tag below to change " + title }
              ?? "Select a branch or tag below to change " + title)
        .disabled(isLoading)
    }

    private func revealEditingRevision() {
        if let editingRevision {
            tab = editingRevision.hasPrefix("refs/tags/") ? 1 : 0
        }
    }

    private func referenceName(_ reference: String) -> String {
        for prefix in ["refs/heads/", "refs/remotes/", "refs/tags/"] {
            if reference.hasPrefix(prefix) {
                return String(reference.dropFirst(prefix.count))
            }
        }
        return reference
    }

    private func swapComparison() {
        guard let compareRevision else { return }
        let previousBase = baseRevision
        baseRevision = compareRevision
        self.compareRevision = previousBase
        revealEditingRevision()
    }

    private func loadReferences() async throws {
        let updatedBranches = try await Process.output(GitBranch(directory: folder.url))
        let updatedRemoteBranches = try await Process.output(GitBranch(directory: folder.url, isRemote: true))
            .filter { !$0.name.contains(" -> ") }
        let updatedTags = try await Process.output(GitTag(directory: folder.url))
        branches = updatedBranches
        remoteBranches = updatedRemoteBranches
        tags = updatedTags

        if baseRevision != "HEAD",
           !branches.contains(where: { revision(for: $0) == baseRevision }),
           !remoteBranches.contains(where: { "refs/remotes/" + $0.name == baseRevision }),
           !tags.contains(where: { "refs/tags/" + $0 == baseRevision }) {
            baseRevision = "HEAD"
        }

        if let compareRevision,
           compareRevision != "HEAD",
           !branches.contains(where: { revision(for: $0) == compareRevision }),
           !remoteBranches.contains(where: { "refs/remotes/" + $0.name == compareRevision }),
           !tags.contains(where: { "refs/tags/" + $0 == compareRevision }) {
            self.compareRevision = nil
        }
    }
}
