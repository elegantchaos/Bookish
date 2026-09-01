import BookishCoding
import BookishDatastore
import BookishImporter
import BookishImporterSamples
import BookishRecord
import Foundation
import Observation

/// Coordinates prototype datastore loading, seeding, selection, and actions for the UI.
@MainActor
@Observable
public final class DatastorePrototypeHarness {
  /// The navigation and routing service used by the prototype browser.
  @ObservationIgnored public let navigation: DatastorePrototypeNavigationService

  /// The identifiers of layout records currently available from the record service.
  public private(set) var layoutIDs: [BookishRecordID] = []

  /// Increments whenever the record projection is refreshed.
  public private(set) var revision = 0

  /// The current user-facing status message.
  public private(set) var status = "Loading"

  /// The current import progress, when an import is active.
  public private(set) var importProgress: BookishImportProgress?

  /// The selected layout record identifier.
  public var selectedLayoutID: BookishRecordID?

  /// Whether the interchange import file picker is visible.
  public var isImportingInterchange = false

  /// Whether the Delicious Library import file picker is visible.
  public var isImportingDeliciousLibrary = false

  /// Whether the interchange export file picker is visible.
  public var isExportingInterchange = false

  /// The document currently being exported.
  public var interchangeExportDocument = PrototypeInterchangeDocument()

  private let bookID = BookishRecordID("prototype-book")
  private let layoutID = BookishRecordID("prototype-book-layout")
  private let compactLayoutID = BookishRecordID("prototype-book-compact-layout")
  private let authorID = BookishRecordID("prototype-author")
  private let directoryURL: URL?
  private var prototype: DatastorePrototype?

  /// Creates an empty harness ready to load the prototype datastore.
  public init(
    directoryURL: URL? = nil,
    navigation: DatastorePrototypeNavigationService = DatastorePrototypeNavigationService()
  ) {
    self.directoryURL = directoryURL
    self.navigation = navigation
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
    guard let prototype, let recordID = navigation.selectedRecordID else {
      return
    }

    do {
      let record = try await prototype.recordService.record(id: recordID)
      let mutation = MutationRecord(
        operation: .setProperty(
          recordID: recordID,
          kind: record?.kind ?? "record",
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

  /// Imports records from a Bookish interchange JSON file.
  public func importInterchange(from url: URL) async {
    await importFile(from: url, using: BookishInterchangeImporter())
  }

  /// Requests an interchange file import.
  public func requestInterchangeImport() {
    isImportingInterchange = true
  }

  /// Requests a Delicious Library file import.
  public func requestDeliciousLibraryImport() {
    isImportingDeliciousLibrary = true
  }

  /// Requests an interchange file export.
  public func requestInterchangeExport() async {
    do {
      interchangeExportDocument = PrototypeInterchangeDocument(
        data: try await exportInterchangeData())
      isExportingInterchange = true
    } catch {
      report(error: error)
    }
  }

  /// Handles successful completion of the interchange export panel.
  public func didExportInterchange() {
    report(message: "Exported interchange file")
  }

  /// Resets the prototype by removing every stored record and mutation.
  public func reset() async {
    guard let prototype else {
      status = DatastorePrototypeHarnessError.notLoaded.localizedDescription
      return
    }

    do {
      try await prototype.mutationStore.removeAll()
      try await prototype.recordStore.removeAll()
      navigation.reset()
      selectedLayoutID = nil
      try await refresh()
      status = "Reset prototype datastore"
    } catch {
      status = error.localizedDescription
    }
  }

  /// Imports records from Bookish interchange JSON data.
  public func importInterchange(data: Data) async {
    await importRecords(from: data, using: BookishInterchangeImporter())
  }

  /// Imports records from a Delicious Library XML property-list file.
  public func importDeliciousLibrary(from url: URL) async {
    await importFile(from: url, using: DeliciousLibraryImporter())
  }

  /// Imports records from Delicious Library XML property-list data.
  public func importDeliciousLibrary(data: Data) async {
    await importRecords(from: data, using: DeliciousLibraryImporter())
  }

  /// Imports one of the Delicious Library sample files bundled with Bookish.
  public func importDeliciousLibrary(sample: DeliciousLibrarySample) async {
    do {
      await importDeliciousLibrary(
        from: try BookishImporterSamples.deliciousLibraryURL(for: sample))
    } catch {
      report(error: error)
    }
  }

  /// Consumes the event stream from any Bookish importer and applies its record upserts.
  public func importRecords<Importer: BookishImporter>(
    from input: Importer.Input,
    using importer: Importer
  ) async {
    guard let prototype else {
      status = DatastorePrototypeHarnessError.notLoaded.localizedDescription
      return
    }

    var importedRecordCount = 0
    var firstRecord: BookishRecord?
    var displayName = importer.descriptor.displayName
    let clock = ContinuousClock()
    var lastProjectionRefresh = clock.now

    do {
      for try await event in importer.importEvents(from: input) {
        try Task.checkCancellation()

        switch event {
        case .started(let start):
          displayName = start.importer.displayName
          importProgress = BookishImportProgress(
            message: "Reading \(displayName)", completed: 0, total: start.total)
          status = "Reading \(displayName)"

        case .progress(let progress):
          importProgress = progress
          status = progress.message

        case .records(let records):
          for record in records {
            try await prototype.mutationService.perform(.upsertRecord(record))
          }
          importedRecordCount += records.count
          firstRecord = firstRecord ?? records.first(where: { $0.kind == "book" }) ?? records.first
          if lastProjectionRefresh.duration(to: clock.now) >= .seconds(1) {
            try await refresh()
            lastProjectionRefresh = clock.now
          }

        case .diagnostic(let diagnostic):
          status = diagnostic

        case .finished:
          break
        }
      }

      try await refresh()
      if let firstRecord {
        navigation.select(kind: firstRecord.kind)
        navigation.select(recordID: firstRecord.id)
      }
      status =
        "Imported \(importedRecordCount) \(displayName) \(importedRecordCount == 1 ? "record" : "records")"
    } catch is CancellationError {
      status = "Import cancelled"
    } catch {
      status = error.localizedDescription
    }

    importProgress = nil
  }

  /// Exports the current materialised records as Bookish interchange JSON data.
  public func exportInterchangeData() async throws -> Data {
    guard let prototype else {
      throw DatastorePrototypeHarnessError.notLoaded
    }

    var records: [BookishRecord] = []
    for id in navigation.recordIDs {
      guard let record = try await prototype.recordService.record(id: id) else {
        throw DatastorePrototypeHarnessError.notLoaded
      }
      records.append(record)
    }
    let file = BookishInterchangeFile(root: navigation.selectedRecordID, records: records)
    return try BookishInterchangeCodec().encode(file)
  }

  /// Returns a record by resolving it from the record service.
  public func record(id: BookishRecordID) async throws -> BookishRecord? {
    try await prototype?.recordService.record(id: id)
  }

  /// Returns the selected record by resolving it from the record service.
  public func selectedRecord() async throws -> BookishRecord? {
    guard let selectedRecordID = navigation.selectedRecordID else {
      return nil
    }

    return try await record(id: selectedRecordID)
  }

  /// Returns all stored mutations for the debug mutation window.
  public func mutations() async throws -> [MutationRecord] {
    guard let prototype else {
      throw DatastorePrototypeHarnessError.notLoaded
    }

    return try await prototype.mutationStore.mutations()
  }

  /// Returns the selected layout by resolving it from the record service.
  public func selectedLayout() async throws -> BookishRecord? {
    guard let selectedLayoutID else {
      return nil
    }

    return try await record(id: selectedLayoutID)
  }

  /// Returns the local directory used for prototype datastore files.
  public func localDatastoreDirectory() throws -> URL {
    try datastoreDirectory()
  }

  /// Reports an arbitrary user-facing message.
  public func report(message: String) {
    status = message
  }

  /// Reports an arbitrary user-facing error.
  public func report(error: Error) {
    status = error.localizedDescription
  }

  private func setStatus(_ value: String) async {
    guard let prototype, let recordID = navigation.selectedRecordID else {
      return
    }

    do {
      let record = try await prototype.recordService.record(id: recordID)
      try await prototype.mutationService.perform(
        .setProperty(
          recordID: recordID, kind: record?.kind ?? "record", key: "status", value: .string(value))
      )
      try await refresh()
      status = "Set status to \(value)"
    } catch {
      status = error.localizedDescription
    }
  }

  private func importFile<Importer: BookishImporter>(
    from url: URL,
    using importer: Importer
  ) async where Importer.Input == Data {
    do {
      let canAccess = url.startAccessingSecurityScopedResource()
      defer {
        if canAccess {
          url.stopAccessingSecurityScopedResource()
        }
      }

      let data = try Data(contentsOf: url)
      await importRecords(from: data, using: importer)
    } catch {
      status = error.localizedDescription
    }
  }

  private func refresh() async throws {
    guard let prototype else {
      return
    }

    let records = try await prototype.recordService.records()
    navigation.update(records: records)
    layoutIDs = try await prototype.recordService.recordIDs(matching: .kind("layout"))
    revision += 1
    try await updateLayoutSelection(using: prototype)
  }

  private func seedIfNeeded(using prototype: DatastorePrototype) async throws {
    if try await prototype.recordService.record(id: bookID) == nil {
      try await prototype.mutationService.perform(
        .upsertRecord(
          BookishRecord(
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
          BookishRecord(
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
          BookishRecord(
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
          BookishRecord(
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
    if let directoryURL {
      try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
      return directoryURL
    }

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

  private func updateLayoutSelection(using prototype: DatastorePrototype) async throws {
    if selectedLayoutID == nil, try await prototype.recordService.record(id: layoutID) != nil {
      selectedLayoutID = layoutID
    }

    if let selectedLayoutID, try await prototype.recordService.record(id: selectedLayoutID) != nil {
      return
    }

    selectedLayoutID = layoutIDs.first
  }
}

private enum DatastorePrototypeHarnessError: LocalizedError {
  case notLoaded

  var errorDescription: String? {
    switch self {
    case .notLoaded:
      "The prototype datastore is not loaded."
    }
  }
}
