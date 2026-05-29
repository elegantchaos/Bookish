import BookishDatastore
import Foundation
import Observation

/// Coordinates prototype datastore loading, seeding, selection, and actions for the UI.
@MainActor
@Observable
public final class DatastorePrototypeHarness {
  /// The records currently loaded from the record service.
  public private(set) var records: [StoredRecord] = []

  /// The layout records currently loaded from the record service.
  public private(set) var layouts: [StoredRecord] = []

  /// The durable mutations currently loaded from the mutation store.
  public private(set) var mutations: [MutationRecord] = []

  /// The current user-facing status message.
  public private(set) var status = "Loading"

  /// The selected browser item.
  public var selection: PrototypeBrowserSelection?

  /// The selected layout record identifier.
  public var selectedLayoutID: RecordID?

  private let bookID = RecordID("prototype-book")
  private let layoutID = RecordID("prototype-book-layout")
  private let compactLayoutID = RecordID("prototype-book-compact-layout")
  private let authorID = RecordID("prototype-author")
  private var prototype: DatastorePrototype?

  /// Creates an empty harness ready to load the prototype datastore.
  public init() {}

  /// The selected record, if the current selection is a record.
  public var selectedRecord: StoredRecord? {
    guard case .record(let id) = selection else {
      return nil
    }

    return record(id: id)
  }

  /// The selected mutation, if the current selection is a mutation.
  public var selectedMutation: MutationRecord? {
    guard case .mutation(let id) = selection else {
      return nil
    }

    return mutation(id: id)
  }

  /// The active layout record used by row and detail views.
  public var selectedLayout: StoredRecord? {
    record(id: selectedLayoutID)
  }

  /// Loads, seeds, and refreshes the prototype datastore.
  public func load() async {
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

  /// Applies a local mutation that marks the selected record as currently being read.
  public func markReading() async {
    await setStatus("Reading")
  }

  /// Applies a local mutation that marks the selected record as finished.
  public func markFinished() async {
    await setStatus("Finished")
  }

  /// Simulates a remotely-arrived mutation for the selected record.
  public func simulateRemoteUpdate() async {
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
    mutations = try await prototype.mutationStore.mutations()
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

  private func mutation(id: MutationID?) -> MutationRecord? {
    guard let id else {
      return nil
    }

    return mutations.first { $0.id == id }
  }

  private func updateSelection() {
    switch selection {
    case .record(let id) where record(id: id) != nil:
      break

    case .mutation(let id) where mutation(id: id) != nil:
      break

    default:
      selection = records.first.map { .record($0.id) } ?? mutations.first.map { .mutation($0.id) }
    }

    if selectedLayoutID == nil, record(id: layoutID) != nil {
      selectedLayoutID = layoutID
    }

    if record(id: selectedLayoutID) == nil {
      selectedLayoutID = layouts.first?.id
    }
  }
}

/// Identifies the selected item in the prototype datastore browser.
public enum PrototypeBrowserSelection: Hashable, Sendable {
  /// A materialised record selection.
  case record(RecordID)

  /// A mutation log entry selection.
  case mutation(MutationID)
}
