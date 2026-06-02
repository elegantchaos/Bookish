import BookishDatastore
import BookishRecord
import BookishRecordView
import SwiftUI
import UniformTypeIdentifiers

/// The root view for the datastore prototype app.
public struct DatastorePrototypeHarnessView: View {
  @State private var harness = DatastorePrototypeHarness()
  @State private var isImportingInterchange = false
  @State private var isImportingDeliciousLibrary = false
  @State private var isExportingInterchange = false
  @State private var interchangeExportDocument = PrototypeInterchangeDocument()

  /// Creates the prototype harness view.
  public init() {}

  /// The SwiftUI content for the prototype app.
  public var body: some View {
    NavigationSplitView {
      RecordIndexView(harness: harness)
    } detail: {
      RecordDetailView(harness: harness)
    }
    .toolbar {
      PrototypeToolbar(
        harness: harness,
        importInterchange: { isImportingInterchange = true },
        importDeliciousLibrary: { isImportingDeliciousLibrary = true },
        exportInterchange: prepareInterchangeExport
      )
    }
    .safeAreaInset(edge: .bottom) {
      PrototypeStatusBar(harness: harness)
    }
    .fileImporter(
      isPresented: $isImportingInterchange,
      allowedContentTypes: [.json],
      onCompletion: handleInterchangeImport
    )
    .fileImporter(
      isPresented: $isImportingDeliciousLibrary,
      allowedContentTypes: [.xml],
      onCompletion: handleDeliciousLibraryImport
    )
    .fileExporter(
      isPresented: $isExportingInterchange,
      document: interchangeExportDocument,
      contentType: .json,
      defaultFilename: "Bookish Interchange",
      onCompletion: handleInterchangeExport
    )
    .task {
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

  private func prepareInterchangeExport() {
    do {
      interchangeExportDocument = PrototypeInterchangeDocument(
        data: try harness.exportInterchangeData())
      isExportingInterchange = true
    } catch {
      Task { @MainActor in
        harness.report(error: error)
      }
    }
  }

  private func handleInterchangeExport(_ result: Result<URL, Error>) {
    switch result {
    case .success:
      Task { @MainActor in
        harness.report(message: "Exported interchange file")
      }

    case .failure(let error):
      Task { @MainActor in
        harness.report(error: error)
      }
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
  @Bindable var harness: DatastorePrototypeHarness
  var importInterchange: () -> Void
  var importDeliciousLibrary: () -> Void
  var exportInterchange: () -> Void

  var body: some ToolbarContent {
    ToolbarItem {
      Picker("Layout", selection: $harness.selectedLayoutID) {
        Text("Default").tag(Optional<BookishRecordID>.none)
        ForEach(harness.layouts) { layout in
          Text(layout.string("title") ?? layout.id.rawValue)
            .tag(Optional(layout.id))
        }
      }
      .pickerStyle(.menu)
    }

    ToolbarItemGroup {
      Menu {
        Button(action: importInterchange) {
          Label("Interchange File", systemImage: "doc.text")
        }

        Button(action: importDeliciousLibrary) {
          Label("Delicious Library File", systemImage: "books.vertical")
        }
      } label: {
        Label("Import", systemImage: "square.and.arrow.down")
      }

      Menu {
        Button(action: exportInterchange) {
          Label("Interchange File", systemImage: "doc.text")
        }
        .disabled(harness.records.isEmpty)
      } label: {
        Label("Export", systemImage: "square.and.arrow.up")
      }
    }

    ToolbarItemGroup {
      Button(action: markReading) {
        Label("Reading", systemImage: "book")
      }
      .disabled(harness.selectedRecord == nil)

      Button(action: markFinished) {
        Label("Finished", systemImage: "checkmark.circle")
      }
      .disabled(harness.selectedRecord == nil)

      Button(action: simulateRemoteUpdate) {
        Label("Remote", systemImage: "icloud.and.arrow.down")
      }
      .disabled(harness.selectedRecord == nil)
    }
  }

  private func markReading() {
    Task { await harness.markReading() }
  }

  private func markFinished() {
    Task { await harness.markFinished() }
  }

  private func simulateRemoteUpdate() {
    Task { await harness.simulateRemoteUpdate() }
  }
}

private struct PrototypeInterchangeDocument: FileDocument {
  static var readableContentTypes: [UTType] {
    [.json]
  }

  static var writableContentTypes: [UTType] {
    [.json]
  }

  var data: Data

  init(data: Data = Data()) {
    self.data = data
  }

  init(configuration: ReadConfiguration) throws {
    self.data = configuration.file.regularFileContents ?? Data()
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: data)
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
