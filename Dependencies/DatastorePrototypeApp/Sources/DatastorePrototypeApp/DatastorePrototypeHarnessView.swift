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
        ForEach(harness.records) { record in
          PrototypeRecordCell(record: record, layout: harness.selectedLayout)
            .tag(PrototypeBrowserSelection.record(record.id))
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
      if let record = harness.selectedRecord {
        PrototypeRecordView(record: record, layout: harness.selectedLayout)
      } else if let mutation = harness.selectedMutation {
        PrototypeMutationView(mutation: mutation)
      } else {
        ContentUnavailableView(
          "No Selection", systemImage: "list.bullet.rectangle", description: Text(harness.status))
      }
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
        ForEach(harness.layouts) { layout in
          Text(layout.string("title") ?? layout.id.rawValue)
            .tag(Optional(layout.id))
        }
      }
      .pickerStyle(.menu)
    }
  }
}

private struct PrototypeStatusBar: View {
  let harness: DatastorePrototypeHarness

  var body: some View {
    HStack {
      Text(harness.status)
      Spacer()
      Text("\(harness.records.count) records")
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
