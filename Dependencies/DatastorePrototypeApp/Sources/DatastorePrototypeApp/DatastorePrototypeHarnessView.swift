import BookishDatastore
import BookishRecord
import BookishRecordView
import CommandsUI
import SwiftUI
import UniformTypeIdentifiers

/// The root view for the datastore prototype app.
public struct DatastorePrototypeHarnessView: View {
  @Bindable private var harness: DatastorePrototypeHarness
  @Environment(DatastorePrototypeNavigationService.self) private var navigation
  private let loadsOnAppear: Bool

  /// Creates the prototype harness view.
  public init(
    harness: DatastorePrototypeHarness = DatastorePrototypeHarness(), loadsOnAppear: Bool = true
  ) {
    self.harness = harness
    self.loadsOnAppear = loadsOnAppear
  }

  /// The SwiftUI content for the prototype app.
  public var body: some View {
    NavigationSplitView {
      RecordKindListView(navigation: navigation)
    } content: {
      RecordIndexView(harness: harness, navigation: navigation)
    } detail: {
      RecordDetailView(harness: harness, navigation: navigation)
    }
    .toolbar {
      PrototypeToolbar(harness: harness)
    }
    .safeAreaInset(edge: .bottom) {
      PrototypeStatusBar(harness: harness)
    }
    .fileImporter(
      isPresented: $harness.isImportingInterchange,
      allowedContentTypes: [.json],
      onCompletion: handleInterchangeImport
    )
    .fileImporter(
      isPresented: $harness.isImportingDeliciousLibrary,
      allowedContentTypes: [.xml],
      onCompletion: handleDeliciousLibraryImport
    )
    .fileExporter(
      isPresented: $harness.isExportingInterchange,
      document: harness.interchangeExportDocument,
      contentType: .json,
      defaultFilename: "Bookish Interchange",
      onCompletion: handleInterchangeExport
    )
    .task {
      guard loadsOnAppear else {
        return
      }
      await harness.load()
    }
  }

  private func handleInterchangeImport(_ result: Result<URL, Error>) {
    guard case .success(let url) = result else {
      return
    }

    Task {
      await harness.importInterchange(from: url)
    }
  }

  private func handleDeliciousLibraryImport(_ result: Result<URL, Error>) {
    guard case .success(let url) = result else {
      return
    }

    Task {
      await harness.importDeliciousLibrary(from: url)
    }
  }

  private func handleInterchangeExport(_ result: Result<URL, Error>) {
    switch result {
    case .success:
      harness.didExportInterchange()

    case .failure(let error):
      harness.report(error: error)
    }
  }
}

private struct RecordKindListView: View {
  let navigation: DatastorePrototypeNavigationService

  var body: some View {
    List(selection: selectedKind) {
      ForEach(navigation.recordKinds, id: \.self) { kind in
        Text(kind.capitalized)
          .tag(Optional(kind))
      }
    }
    .navigationTitle("Records")
  }

  private var selectedKind: Binding<String?> {
    Binding {
      navigation.selectedRecordKind
    } set: { kind in
      navigation.select(kind: kind)
    }
  }
}

private struct RecordIndexView: View {
  let harness: DatastorePrototypeHarness
  let navigation: DatastorePrototypeNavigationService

  var body: some View {
    List(selection: selectedRecordID) {
      ForEach(navigation.selectedRecordIDs, id: \.self) { id in
        PrototypeRecordIDCell(recordID: id, harness: harness)
          .tag(Optional(id))
      }
    }
    .navigationTitle(navigation.selectedRecordKind?.capitalized ?? "Index")
  }

  private var selectedRecordID: Binding<BookishRecordID?> {
    Binding {
      navigation.selectedRecordID
    } set: { recordID in
      navigation.select(recordID: recordID)
    }
  }
}

private struct RecordDetailView: View {
  let harness: DatastorePrototypeHarness
  let navigation: DatastorePrototypeNavigationService

  var body: some View {
    Group {
      if let recordID = navigation.selectedRecordID {
        PrototypeRecordIDDetail(recordID: recordID, harness: harness, navigation: navigation)
      } else {
        ContentUnavailableView(
          "No Selection", systemImage: "list.bullet.rectangle", description: Text(harness.status))
      }
    }
  }
}

private struct PrototypeRecordIDCell: View {
  let recordID: BookishRecordID
  let harness: DatastorePrototypeHarness

  @State private var record: BookishRecord?
  @State private var layout: BookishRecord?

  var body: some View {
    Group {
      if let record {
        PrototypeRecordCell(record: record, layout: layout)
      } else {
        Text(recordID.rawValue)
      }
    }
    .task(id: taskID) {
      await load()
    }
  }

  private var taskID: String {
    "\(recordID.rawValue)-\(harness.selectedLayoutID?.rawValue ?? "")-\(harness.revision)"
  }

  private func load() async {
    do {
      record = try await harness.record(id: recordID)
      layout = try await harness.selectedLayout()
    } catch {
      harness.report(error: error)
    }
  }
}

private struct PrototypeRecordIDDetail: View {
  let recordID: BookishRecordID
  let harness: DatastorePrototypeHarness
  let navigation: DatastorePrototypeNavigationService

  @State private var record: BookishRecord?
  @State private var layout: BookishRecord?

  var body: some View {
    Group {
      if let record {
        PrototypeRecordView(record: record, layout: layout) { field in
          guard let recordID = field.rawValue?.recordValue else {
            return nil
          }

          return AnyView(RecordLinkButton(recordID: recordID, navigation: navigation))
        }
      } else {
        ContentUnavailableView("Loading", systemImage: "book", description: Text(recordID.rawValue))
      }
    }
    .task(id: taskID) {
      await load()
    }
  }

  private var taskID: String {
    "\(recordID.rawValue)-\(harness.selectedLayoutID?.rawValue ?? "")-\(harness.revision)"
  }

  private func load() async {
    do {
      record = try await harness.record(id: recordID)
      layout = try await harness.selectedLayout()
    } catch {
      harness.report(error: error)
    }
  }
}

private struct PrototypeToolbar: ToolbarContent {
  var harness: DatastorePrototypeHarness

  var body: some ToolbarContent {
    ToolbarItem {
      harness.importer(ImportInterchangeCommand())
        .labelStyle(.iconOnly)
    }

    ToolbarItem {
      harness.button(ExportInterchangeCommand())
        .labelStyle(.iconOnly)
    }

    harness.toolbarItem(MarkReadingCommand())
    harness.toolbarItem(MarkFinishedCommand())
    harness.toolbarItem(SimulateRemoteMutationCommand())

    ToolbarItem {
      @Bindable var harness = harness
      Picker("Layout", selection: $harness.selectedLayoutID) {
        Text("Default").tag(Optional<BookishRecordID>.none)
        ForEach(harness.layoutIDs, id: \.self) { id in
          PrototypeLayoutPickerItem(layoutID: id, harness: harness)
        }
      }
      .pickerStyle(.menu)
    }
  }
}

private struct PrototypeLayoutPickerItem: View {
  let layoutID: BookishRecordID
  let harness: DatastorePrototypeHarness

  @State private var title: String?

  var body: some View {
    Text(title ?? layoutID.rawValue)
      .tag(Optional(layoutID))
      .task(id: taskID) {
        await load()
      }
  }

  private var taskID: String {
    "\(layoutID.rawValue)-\(harness.revision)"
  }

  private func load() async {
    do {
      title = try await harness.record(id: layoutID)?.string("title")
    } catch {
      harness.report(error: error)
    }
  }
}

private struct PrototypeStatusBar: View {
  let harness: DatastorePrototypeHarness

  var body: some View {
    HStack {
      Text(harness.status)
      Spacer()
      Text("\(harness.navigation.recordIDs.count) records")
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding()
    .background(.bar)
  }
}

private struct RecordLinkButton: View {
  let recordID: BookishRecordID
  let navigation: DatastorePrototypeNavigationService

  var body: some View {
    Button(recordID.rawValue) {
      navigation.performWithoutWaiting(NavigateToRecordCommand(recordID: recordID))
    }
    .buttonStyle(.link)
  }
}

#if DEBUG
  /// Debug-only mutation history browser kept outside the main record UI.
  public struct DatastorePrototypeMutationDebugView: View {
    private let harness: DatastorePrototypeHarness
    @State private var mutations: [MutationRecord] = []
    @State private var selectedMutationID: MutationID?

    /// Creates the mutation debug window content.
    public init(harness: DatastorePrototypeHarness) {
      self.harness = harness
    }

    /// The SwiftUI content for the mutation debug window.
    public var body: some View {
      NavigationSplitView {
        List(selection: $selectedMutationID) {
          ForEach(mutations) { mutation in
            PrototypeMutationCell(mutation: mutation)
              .tag(Optional(mutation.id))
          }
        }
        .navigationTitle("Mutations")
      } detail: {
        if let mutation = selectedMutation {
          PrototypeMutationView(mutation: mutation)
        } else {
          ContentUnavailableView(
            "No Mutation", systemImage: "list.bullet.rectangle", description: Text(harness.status))
        }
      }
      .task(id: harness.revision) {
        await load()
      }
    }

    private var selectedMutation: MutationRecord? {
      guard let selectedMutationID else {
        return nil
      }

      return mutations.first { $0.id == selectedMutationID }
    }

    private func load() async {
      do {
        mutations = try await harness.mutations()
        if selectedMutation == nil {
          selectedMutationID = mutations.first?.id
        }
      } catch {
        harness.report(error: error)
      }
    }
  }
#endif

#Preview {
  let navigation = DatastorePrototypeNavigationService()
  DatastorePrototypeHarnessView(harness: DatastorePrototypeHarness(navigation: navigation))
    .environment(navigation)
}
