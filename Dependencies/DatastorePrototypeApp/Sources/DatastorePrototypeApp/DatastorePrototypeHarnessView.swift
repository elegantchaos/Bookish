import BookishDatastore
import BookishRecord
import BookishRecordView
import CommandsUI
import SwiftUI
import UniformTypeIdentifiers

/// The root view for the datastore prototype app.
public struct DatastorePrototypeHarnessView: View {
  @Bindable private var harness: DatastorePrototypeHarness
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
      RecordIndexView(harness: harness)
    } detail: {
      RecordDetailView(harness: harness)
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

private struct RecordIndexView: View {
  @Bindable var harness: DatastorePrototypeHarness

  var body: some View {
    List(selection: $harness.selection) {
      Section("Records") {
        ForEach(harness.recordIDs, id: \.self) { id in
          PrototypeRecordIDCell(recordID: id, harness: harness)
            .tag(PrototypeBrowserSelection.record(id))
        }
      }

      Section("Mutations") {
        ForEach(harness.mutations) { mutation in
          PrototypeMutationCell(mutation: mutation)
            .tag(PrototypeBrowserSelection.mutation(mutation.id))
        }
      }
    }
    .navigationTitle("Datastore")
  }
}

private struct RecordDetailView: View {
  @Bindable var harness: DatastorePrototypeHarness

  var body: some View {
    Group {
      if let recordID = harness.selectedRecordID {
        PrototypeRecordIDDetail(recordID: recordID, harness: harness)
      } else if let mutation = harness.selectedMutation {
        PrototypeMutationView(mutation: mutation)
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

  @State private var record: BookishRecord?
  @State private var layout: BookishRecord?

  var body: some View {
    Group {
      if let record {
        PrototypeRecordView(record: record, layout: layout)
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
      Text("\(harness.recordIDs.count) records")
      Text("\(harness.mutations.count) mutations")
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding()
    .background(.bar)
  }
}

#Preview {
  DatastorePrototypeHarnessView()
}
