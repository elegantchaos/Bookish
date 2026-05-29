import BookishDatastore
import BookishRecordView
import SwiftUI

@main
struct DatastorePrototypeApplication: App {
  var body: some Scene {
    WindowGroup {
      DatastorePrototypeHarnessView()
    }
  }
}

@MainActor
@Observable
private final class DatastorePrototypeHarness {
  private(set) var records: [StoredRecord] = []
  private(set) var layouts: [StoredRecord] = []
  private(set) var mutationCount = 0
  private(set) var status = "Loading"
  var selectedRecordID: RecordID?
  var selectedLayoutID: RecordID?

  private let bookID = RecordID("prototype-book")
  private let layoutID = RecordID("prototype-book-layout")
  private let compactLayoutID = RecordID("prototype-book-compact-layout")
  private let authorID = RecordID("prototype-author")
  private var prototype: DatastorePrototype?

  var selectedRecord: StoredRecord? {
    record(id: selectedRecordID) ?? records.first
  }

  var selectedLayout: StoredRecord? {
    record(id: selectedLayoutID)
  }

  func load() async {
    do {
      let directory = try datastoreDirectory()
      let prototype = try await DatastorePrototype(directoryURL: directory)
      self.prototype = prototype

      try await seedIfNeeded(using: prototype)
      try await refresh()
      status = "Ready"
    } catch {
      status = error.localizedDescription
    }
  }

  func markReading() async {
    await setStatus("Reading")
  }

  func markFinished() async {
    await setStatus("Finished")
  }

  func simulateRemoteUpdate() async {
    guard let prototype, let recordID = selectedRecord?.id else {
      return
    }

    do {
      let mutation = MutationRecord(
        operation: .setProperty(
          recordID: recordID,
          kind: selectedRecord?.kind ?? "record",
          key: "note",
          value: .string(
            "Remote mutation arrived at \(Date().formatted(date: .omitted, time: .shortened))")
        )
      )
      try await prototype.mutationService.receiveRemoteMutation(mutation)
      try await refresh()
      status = "Applied remote mutation"
    } catch {
      status = error.localizedDescription
    }
  }

  private func setStatus(_ value: String) async {
    guard let prototype, let record = selectedRecord else {
      return
    }

    do {
      try await prototype.mutationService.perform(
        .setProperty(recordID: record.id, kind: record.kind, key: "status", value: .string(value))
      )
      try await refresh()
      status = "Set status to \(value)"
    } catch {
      status = error.localizedDescription
    }
  }

  private func refresh() async throws {
    guard let prototype else {
      return
    }

    records = try await prototype.recordService.records()
    layouts = records.filter { $0.kind == "layout" }
    mutationCount = try await prototype.mutationStore.mutations().count
    updateSelection()
  }

  private func seedIfNeeded(using prototype: DatastorePrototype) async throws {
    if try await prototype.recordService.record(id: bookID) == nil {
      try await prototype.mutationService.perform(
        .upsertRecord(
          StoredRecord(
            id: bookID,
            kind: "book",
            properties: [
              "title": .string("The Left Hand of Darkness"),
              "author": .string("Ursula K. Le Guin"),
              "status": .string("To Read"),
              "format": .string("Paperback"),
              "note": .string("Seeded by the prototype harness"),
            ]
          )
        )
      )
    }

    if try await prototype.recordService.record(id: authorID) == nil {
      try await prototype.mutationService.perform(
        .upsertRecord(
          StoredRecord(
            id: authorID,
            kind: "author",
            properties: [
              "name": .string("Ursula K. Le Guin"),
              "status": .string("Reference"),
              "note": .string("Author record included to make the index browseable."),
            ]
          )
        )
      )
    }

    if try await prototype.recordService.record(id: layoutID) == nil {
      try await prototype.mutationService.perform(
        .upsertRecord(
          StoredRecord(
            id: layoutID,
            kind: "layout",
            properties: [
              "title": .string("Prototype Book"),
              "fields": .list([
                .string("title"), .string("author"), .string("status"), .string("format"),
                .string("note"),
              ]),
            ]
          )
        )
      )
    }

    if try await prototype.recordService.record(id: compactLayoutID) == nil {
      try await prototype.mutationService.perform(
        .upsertRecord(
          StoredRecord(
            id: compactLayoutID,
            kind: "layout",
            properties: [
              "title": .string("Compact Summary"),
              "fields": .list([.string("title"), .string("name"), .string("status")]),
            ]
          )
        )
      )
    }
  }

  private func datastoreDirectory() throws -> URL {
    let applicationSupport = try FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    let directory = applicationSupport.appending(
      path: "BookishDatastorePrototype", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }

  private func record(id: RecordID?) -> StoredRecord? {
    guard let id else {
      return nil
    }

    return records.first { $0.id == id }
  }

  private func updateSelection() {
    if record(id: selectedRecordID) == nil {
      selectedRecordID = records.first?.id
    }

    if selectedLayoutID == nil, record(id: layoutID) != nil {
      selectedLayoutID = layoutID
    }

    if record(id: selectedLayoutID) == nil {
      selectedLayoutID = layouts.first?.id
    }
  }
}

private struct DatastorePrototypeHarnessView: View {
  @State private var harness = DatastorePrototypeHarness()

  var body: some View {
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
    .task {
      await harness.load()
    }
  }
}

private struct RecordIndexView: View {
  @Bindable var harness: DatastorePrototypeHarness

  var body: some View {
    List(selection: $harness.selectedRecordID) {
      ForEach(harness.records) { record in
        PrototypeRecordCell(record: record, layout: harness.selectedLayout)
          .tag(record.id)
      }
    }
    .navigationTitle("Records")
  }
}

private struct RecordDetailView: View {
  @Bindable var harness: DatastorePrototypeHarness

  var body: some View {
    Group {
      if let record = harness.selectedRecord {
        PrototypeRecordView(record: record, layout: harness.selectedLayout)
      } else {
        ContentUnavailableView(
          "No Record", systemImage: "book", description: Text(harness.status))
      }
    }
  }
}

private struct PrototypeToolbar: ToolbarContent {
  @Bindable var harness: DatastorePrototypeHarness

  var body: some ToolbarContent {
    ToolbarItem {
      Picker("Layout", selection: $harness.selectedLayoutID) {
        Text("Default").tag(Optional<RecordID>.none)
        ForEach(harness.layouts) { layout in
          Text(layout.string("title") ?? layout.id.rawValue)
            .tag(Optional(layout.id))
        }
      }
      .pickerStyle(.menu)
    }

    ToolbarItemGroup {
      Button(action: markReading) {
        Label("Reading", systemImage: "book")
      }

      Button(action: markFinished) {
        Label("Finished", systemImage: "checkmark.circle")
      }

      Button(action: simulateRemoteUpdate) {
        Label("Remote", systemImage: "icloud.and.arrow.down")
      }
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

private struct PrototypeStatusBar: View {
  let harness: DatastorePrototypeHarness

  var body: some View {
    HStack {
      Text(harness.status)
      Spacer()
      Text("\(harness.records.count) records")
      Text("\(harness.mutationCount) mutations")
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
