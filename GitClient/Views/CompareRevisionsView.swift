import SwiftUI

struct CompareRevisionsView: View {
    private enum ComparisonSide {
        case base, compare
    }

    var folder: Folder
    @Environment(\.dismiss) private var dismiss
    @State private var tab = 0
    @State private var localBranchRefs: [GitRef] = []
    @State private var remoteBranchRefs: [GitRef] = []
    @State private var tagRefs: [GitRef] = []
    @State private var baseRef: GitRef?
    @State private var compareRef: GitRef?
    @State private var currentRef: GitRef?
    @State private var editingSide: ComparisonSide = .base
    @State private var filterText = ""
    @State private var isLoading = true
    @State private var isFetching = false
    @State private var diffRefreshID = UUID()
    @State private var error: Error?

    private var filteredLocalBranchRefs: [GitRef] {
        localBranchRefs.filter { filterText.isEmpty || $0.name.localizedCaseInsensitiveContains(filterText) }
    }

    private var filteredRemoteBranchRefs: [GitRef] {
        remoteBranchRefs.filter { filterText.isEmpty || $0.name.localizedCaseInsensitiveContains(filterText) }
    }

    private var filteredTagRefs: [GitRef] {
        tagRefs.filter { filterText.isEmpty || $0.name.localizedCaseInsensitiveContains(filterText) }
    }

    private var editingRef: GitRef? {
        editingSide == .base ? baseRef : compareRef
    }

    private var listSelection: Binding<GitRef.ID?> {
        Binding {
            guard let ref = editingRef, (ref.kind == .tag) == (tab == 1) else { return nil }
            return ref.id
        } set: { id in
            guard let ref = allRefs.first(where: { $0.id == id }) else { return }
            if editingSide == .base {
                baseRef = ref
            } else {
                compareRef = ref
            }
        }
    }

    private var allRefs: [GitRef] {
        localBranchRefs + remoteBranchRefs + tagRefs
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
                        if !filteredLocalBranchRefs.isEmpty {
                            Section("Local") {
                                ForEach(filteredLocalBranchRefs) { ref in
                                    HStack {
                                        referenceRow(ref.name, systemImage: ref.systemImage)
                                        Spacer()
                                        if ref.id == currentRef?.id {
                                            Text("Current")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .tag(ref.id)
                                }
                            }
                        }
                        if !filteredRemoteBranchRefs.isEmpty {
                            Section("Remotes") {
                                ForEach(filteredRemoteBranchRefs) { ref in
                                    referenceRow(ref.name, systemImage: ref.systemImage)
                                        .tag(ref.id)
                                }
                            }
                        }
                    }
                    .overlay {
                        if filteredLocalBranchRefs.isEmpty && filteredRemoteBranchRefs.isEmpty {
                            Text(filterText.isEmpty ? "No Branches" : "No Results")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    List(filteredTagRefs, selection: listSelection) { ref in
                        referenceRow(ref.name, systemImage: ref.systemImage)
                            .tag(ref.id)
                    }
                    .overlay {
                        if filteredTagRefs.isEmpty {
                            Text(filterText.isEmpty ? "No Tags" : "No Results")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .safeAreaBar(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
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
                if let baseRef, let compareRef {
                    CommitDiffView(
                        selectionLogID: baseRef.revision,
                        subSelectionLogID: compareRef.revision,
                        showsComparisonControls: false
                    )
                    .environment(\.folder, folder.url)
                    .id(diffRefreshID)
                } else {
                    Text(baseRef == nil
                         ? "Select a branch or tag for Base"
                         : "Select a branch or tag for Compare")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaBar(edge: .bottom) {
                VStack(spacing: 0) {
                    PixelDivider()
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
                compareRef = currentRef ?? GitRef(name: "HEAD", kind: .head)
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
                comparisonSideButton(.base, title: "Base", ref: baseRef)
                Button(action: swapComparison) {
                    Label("Swap the Comparison", systemImage: "arrow.up.arrow.down")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                .help("Swap the Comparison")
                .disabled(baseRef == nil || compareRef == nil || isLoading)
            }
            comparisonSideButton(.compare, title: "Compare", ref: compareRef)
        }
        .padding(10)
    }

    private func comparisonSideButton(_ side: ComparisonSide, title: String, ref: GitRef?) -> some View {
        Button {
            editingSide = side
            revealEditingRevision()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let ref {
                        referenceRow(ref.name, systemImage: ref.systemImage)
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
        .help("Select a branch or tag below to change \(title)")
        .disabled(isLoading)
    }

    private func revealEditingRevision() {
        if let editingRef {
            tab = editingRef.kind == .tag ? 1 : 0
        }
    }

    private func swapComparison() {
        guard let baseRef, let compareRef else { return }
        let previousBase = baseRef
        self.baseRef = compareRef
        self.compareRef = previousBase
        revealEditingRevision()
    }

    private func loadReferences() async throws {
        let updatedBranches = try await Process.output(GitBranch(directory: folder.url))
        let updatedRemoteBranches = try await Process.output(GitBranch(directory: folder.url, isRemote: true))
            .filter { !$0.name.contains(" -> ") }
        let updatedTags = try await Process.output(GitTag(directory: folder.url))
        localBranchRefs = updatedBranches.map { branch in
            branch.isDetached
                ? GitRef(name: branch.name, kind: .head)
                : GitRef(name: branch.name, kind: .localBranch)
        }
        currentRef = zip(updatedBranches, localBranchRefs)
            .first(where: { $0.0.isCurrent })?.1
        remoteBranchRefs = updatedRemoteBranches.map {
            GitRef(name: $0.name, kind: .remoteBranch)
        }
        tagRefs = updatedTags.map {
            GitRef(name: $0, kind: .tag)
        }

        if let baseRef {
            self.baseRef = allRefs.first(where: { $0.id == baseRef.id })
        }

        if let compareRef {
            self.compareRef = allRefs.first(where: { $0.id == compareRef.id })
        }
    }
}
