import BookishDatastore
import BookishRecord
import BookishRecordView
import CommandsUI
import SwiftUI
import UniformTypeIdentifiers

/// The root view for the datastore app.
public struct BookishHarnessView: View {
  @Bindable private var harness: BookishHarness
  @Environment(BookishNavigationService.self) private var navigation
  private let loadsOnAppear: Bool

  /// Creates the datastore harness view.
  public init(
    harness: BookishHarness = BookishHarness(), loadsOnAppear: Bool = true
  ) {
    self.harness = harness
    self.loadsOnAppear = loadsOnAppear
  }

  /// The SwiftUI content for the datastore app.
  public var body: some View {
    NavigationSplitView {
      BrowserIndexListView(harness: harness, navigation: navigation)
    } content: {
      RecordIndexView(harness: harness, navigation: navigation)
    } detail: {
      RecordDetailView(harness: harness, navigation: navigation)
    }
    .toolbar {
      BookishToolbar(harness: harness)
    }
    .safeAreaInset(edge: .bottom) {
      BookishStatusBar(harness: harness)
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
    switch result {
    case .success(let url):
      Task {
        await harness.importInterchange(from: url)
      }

    case .failure(let error):
      harness.report(error: error)
    }
  }

  private func handleDeliciousLibraryImport(_ result: Result<URL, Error>) {
    switch result {
    case .success(let url):
      Task {
        await harness.importDeliciousLibrary(from: url)
      }

    case .failure(let error):
      harness.report(error: error)
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

private struct BrowserIndexListView: View {
  let harness: BookishHarness
  let navigation: BookishNavigationService

  var body: some View {
    List(selection: selectedRecordIndexID) {
      ForEach(navigation.recordIndexes) { recordIndex in
        Text(recordIndex.name)
          .tag(Optional(recordIndex.id))
      }
    }
    .navigationTitle("Records")
  }

  private var selectedRecordIndexID: Binding<BookishRecordID?> {
    Binding {
      navigation.selectedRecordIndexID
    } set: { recordIndexID in
      Task {
        await harness.select(recordIndexID: recordIndexID)
      }
    }
  }
}

private struct RecordIndexView: View {
  let harness: BookishHarness
  let navigation: BookishNavigationService

  @State private var layout: BookishRecord?
  @State private var presentationsByKind: [String: [BookishRecord]] = [:]

  var body: some View {
    List(selection: selectedRecordID) {
      ForEach(navigation.selectedRecordResult?.records ?? []) { record in
        BookishRecordCell(
          record: record,
          layout: layout,
          presentationResolver: CascadingPresentationResolver(
            presentationRecords: presentationsByKind[record.kind] ?? [])
        )
        .tag(Optional(record.id))
      }
    }
    .navigationTitle(navigation.selectedRecordIndexName ?? "Index")
    .task(id: taskID) {
      await loadPresentation()
    }
  }

  private var selectedRecordID: Binding<BookishRecordID?> {
    Binding {
      navigation.selectedRecordID
    } set: { recordID in
      navigation.select(recordID: recordID)
    }
  }

  private var taskID: String {
    "\(navigation.selectedRecordIndexID?.rawValue ?? "")-\(harness.selectedLayoutID?.rawValue ?? "")-\(harness.revision)"
  }

  private func loadPresentation() async {
    do {
      layout = try await harness.selectedLayout()
      var presentationsByKind: [String: [BookishRecord]] = [:]
      for kind in Set(navigation.selectedRecordResult?.records.map(\.kind) ?? []) {
        presentationsByKind[kind] = try await harness.presentations(for: kind, layout: layout)
      }
      self.presentationsByKind = presentationsByKind
    } catch {
      harness.report(error: error)
    }
  }
}

private struct RecordDetailView: View {
  let harness: BookishHarness
  let navigation: BookishNavigationService

  var body: some View {
    Group {
      if let recordID = navigation.selectedRecordID {
        BookishRecordIDDetail(recordID: recordID, harness: harness, navigation: navigation)
      } else {
        ContentUnavailableView(
          "No Selection", systemImage: "list.bullet.rectangle", description: Text(harness.status))
      }
    }
  }
}

private struct BookishRecordIDCell: View {
  let recordID: BookishRecordID
  let harness: BookishHarness

  @State private var record: BookishRecord?
  @State private var layout: BookishRecord?
  @State private var presentationRecords: [BookishRecord] = []

  var body: some View {
    Group {
      if let record {
        BookishRecordCell(
          record: record,
          layout: layout,
          presentationResolver: CascadingPresentationResolver(
            presentationRecords: presentationRecords))
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
      if let record {
        presentationRecords = try await harness.presentations(for: record.kind, layout: layout)
      }
    } catch {
      harness.report(error: error)
    }
  }
}

private struct BookishRecordIDDetail: View {
  let recordID: BookishRecordID
  let harness: BookishHarness
  let navigation: BookishNavigationService

  @State private var record: BookishRecord?
  @State private var layout: BookishRecord?
  @State private var presentationRecords: [BookishRecord] = []

  var body: some View {
    Group {
      if let record {
        BookishRecordView(
          record: record,
          layout: layout,
          presentationResolver: CascadingPresentationResolver(
            presentationRecords: presentationRecords)
        ) {
          field in
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
    "\(recordID.rawValue)-\(navigation.selectedRecordIndexID?.rawValue ?? "")-\(harness.selectedLayoutID?.rawValue ?? "")-\(harness.revision)"
  }

  private func load() async {
    do {
      record = try await harness.record(id: recordID)
      layout = try await harness.selectedLayout()
      if let record {
        presentationRecords = try await harness.presentations(for: record.kind, layout: layout)
      }
    } catch {
      harness.report(error: error)
    }
  }
}

private struct BookishToolbar: ToolbarContent {
  var harness: BookishHarness

  var body: some ToolbarContent {
    ToolbarItem {
      harness.button(ImportInterchangeCommand())
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
        ForEach(harness.compatibleLayoutIDs, id: \.self) { id in
          BookishLayoutPickerItem(layoutID: id, harness: harness)
        }
      }
      .pickerStyle(.menu)
    }
  }
}

private struct BookishLayoutPickerItem: View {
  let layoutID: BookishRecordID
  let harness: BookishHarness

  @State private var name: String?

  var body: some View {
    Text(name ?? layoutID.rawValue)
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
      name = try await harness.record(id: layoutID)?.string(BookishRecordKey.name)
    } catch {
      harness.report(error: error)
    }
  }
}

private struct BookishStatusBar: View {
  let harness: BookishHarness

  var body: some View {
    HStack {
      status
      Spacer()
      Text("\(harness.navigation.recordIDs.count) records")
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding()
    .background(.bar)
  }

  @ViewBuilder
  private var status: some View {
    if let progress = harness.importProgress {
      if let total = progress.total {
        ProgressView(
          progress.message,
          value: Double(progress.completed),
          total: Double(total)
        )
      } else {
        ProgressView(progress.message)
      }
    } else {
      Text(harness.status)
    }
  }
}

private struct RecordLinkButton: View {
  let recordID: BookishRecordID
  let navigation: BookishNavigationService

  var body: some View {
    Button(recordID.rawValue) {
      navigation.performWithoutWaiting(NavigateToRecordCommand(recordID: recordID))
    }
    #if os(macOS)
      .buttonStyle(.link)
    #endif
  }
}

#if DEBUG
  /// Debug-only mutation history browser kept outside the main record UI.
  public struct BookishMutationDebugView: View {
    private let harness: BookishHarness
    @State private var mutations: [MutationRecord] = []
    @State private var selectedMutationID: MutationID?

    /// Creates the mutation debug window content.
    public init(harness: BookishHarness) {
      self.harness = harness
    }

    /// The SwiftUI content for the mutation debug window.
    public var body: some View {
      NavigationSplitView {
        List(selection: $selectedMutationID) {
          ForEach(mutations) { mutation in
            BookishMutationCell(mutation: mutation)
              .tag(Optional(mutation.id))
          }
        }
        .navigationTitle("Mutations")
      } detail: {
        if let mutation = selectedMutation {
          BookishMutationView(mutation: mutation)
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
  let navigation = BookishNavigationService()
  BookishHarnessView(harness: BookishHarness(navigation: navigation))
    .environment(navigation)
}
