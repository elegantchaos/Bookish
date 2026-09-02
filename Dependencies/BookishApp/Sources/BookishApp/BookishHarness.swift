import BookishCoding
import BookishDatastore
import BookishImporter
import BookishImporterSamples
import BookishRecord
import Foundation
import Observation

/// Coordinates datastore loading, seeding, selection, and actions for the UI.
@MainActor
@Observable
public final class BookishHarness {
  /// The navigation and routing service used by the datastore browser.
  @ObservationIgnored public let navigation: BookishNavigationService

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
  public var interchangeExportDocument = BookishInterchangeDocument()

  private let bookID = BookishRecordID("datastore-book")
  private let layoutID = BookishRecordID("datastore-book-layout")
  private let compactLayoutID = BookishRecordID("datastore-book-compact-layout")
  private let authorID = BookishRecordID("datastore-author")
  private let seedSourceID = "com.elegantchaos.bookish.seed"
  private let directoryURL: URL?
  private var datastore: BookishDatastore?

  /// Creates an empty harness ready to load the datastore.
  public init(
    directoryURL: URL? = nil,
    navigation: BookishNavigationService = BookishNavigationService()
  ) {
    self.directoryURL = directoryURL
    self.navigation = navigation
  }

  /// Loads, seeds, and refreshes the datastore.
  public func load() async {
    do {
      let directory = try datastoreDirectory()
      let datastore = try await BookishDatastore(directoryURL: directory)
      self.datastore = datastore

      try await seedIfNeeded(using: datastore)
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
    guard let datastore, let recordID = navigation.selectedRecordID else {
      return
    }

    do {
      let record = try await datastore.recordService.record(id: recordID)
      let mutation = MutationRecord(
        operation: .setProperty(
          recordID: recordID,
          kind: record?.kind ?? BookishRecordKind.record,
          key: BookishRecordKey.note,
          value: .string(
            "Remote mutation arrived at \(Date().formatted(date: .omitted, time: .shortened))")
        )
      )
      try await datastore.mutationService.receiveRemoteMutation(mutation)
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
      interchangeExportDocument = BookishInterchangeDocument(
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

  /// Resets the datastore by removing every stored record and mutation.
  public func reset() async {
    guard let datastore else {
      status = BookishHarnessError.notLoaded.localizedDescription
      return
    }

    do {
      try await datastore.mutationStore.removeAll()
      try await datastore.recordStore.removeAll()
      navigation.reset()
      selectedLayoutID = nil
      try await refresh()
      status = "Reset datastore"
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
    guard let datastore else {
      status = BookishHarnessError.notLoaded.localizedDescription
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
            try await datastore.mutationService.perform(.upsertRecord(record))
          }
          importedRecordCount += records.count
          firstRecord =
            firstRecord ?? records.first(where: { $0.kind == BookishRecordKind.book })
            ?? records.first
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
    guard let datastore else {
      throw BookishHarnessError.notLoaded
    }

    let records = try await datastore.recordService.records(
      matching: RecordQuery(sort: [.kind, .id]))
    let file = BookishInterchangeFile(root: navigation.selectedRecordID, records: records)
    return try BookishInterchangeCodec().encode(file)
  }

  /// Returns a record by resolving it from the record service.
  public func record(id: BookishRecordID) async throws -> BookishRecord? {
    try await datastore?.recordService.record(id: id)
  }

  /// Returns the selected record by resolving it from the record service.
  public func selectedRecord() async throws -> BookishRecord? {
    guard let selectedRecordID = navigation.selectedRecordID else {
      return nil
    }

    return try await record(id: selectedRecordID)
  }

  /// Selects a top-level browser index and refreshes its content query result.
  public func select(recordIndexID: BookishRecordID?) async {
    guard let datastore else {
      status = BookishHarnessError.notLoaded.localizedDescription
      return
    }

    do {
      navigation.select(recordIndexID: recordIndexID)
      try await refreshSelectedRecordIndex(using: datastore)
    } catch {
      report(error: error)
    }
  }

  /// Selects the next top-level browser index.
  public func selectNextRecordIndex() async {
    await selectRecordIndex(offset: 1)
  }

  /// Selects the previous top-level browser index.
  public func selectPreviousRecordIndex() async {
    await selectRecordIndex(offset: -1)
  }

  /// Returns all stored mutations for the debug mutation window.
  public func mutations() async throws -> [MutationRecord] {
    guard let datastore else {
      throw BookishHarnessError.notLoaded
    }

    return try await datastore.mutationStore.mutations()
  }

  /// Returns the selected layout by resolving it from the record service.
  public func selectedLayout() async throws -> BookishRecord? {
    guard let selectedLayoutID else {
      return nil
    }

    return try await record(id: selectedLayoutID)
  }

  /// Returns the local directory used for datastore files.
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
    guard let datastore, let recordID = navigation.selectedRecordID else {
      return
    }

    do {
      let record = try await datastore.recordService.record(id: recordID)
      try await datastore.mutationService.perform(
        .setProperty(
          recordID: recordID, kind: record?.kind ?? BookishRecordKind.record,
          key: BookishRecordKey.status, value: .string(value))
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
    guard let datastore else {
      return
    }

    let recordIndexResult = try await datastore.recordQueryService.result(
      matching: recordIndexQuery)
    navigation.update(recordIndexResult: recordIndexResult)
    try await refreshSelectedRecordIndex(using: datastore)
    layoutIDs = try await datastore.recordService.recordIDs(
      matching: .kind(BookishRecordKind.layout))
    revision += 1
    try await updateLayoutSelection(using: datastore)
  }

  private func seedIfNeeded(using datastore: BookishDatastore) async throws {
    for indexRecord in try seedRecordIndexes() {
      if try await datastore.recordService.record(id: indexRecord.id) == nil {
        try await datastore.mutationService.perform(.upsertRecord(indexRecord))
      }
    }

    if try await datastore.recordService.record(id: authorID) == nil {
      try await datastore.mutationService.perform(
        .upsertRecord(
          BookishRecord(
            id: authorID,
            kind: BookishRecordKind.person,
            properties: [
              BookishRecordKey.name: .string("Ursula K. Le Guin"),
              BookishRecordKey.source: .string(seedSourceID),
              BookishRecordKey.status: .string("Reference"),
              BookishRecordKey.note: .string(
                "Person record included to make the index browseable."),
            ]
          )
        )
      )
    }

    if try await datastore.recordService.record(id: bookID) == nil {
      try await datastore.mutationService.perform(
        .upsertRecord(
          BookishRecord(
            id: bookID,
            kind: BookishRecordKind.book,
            properties: [
              BookishRecordKey.title: .string("The Left Hand of Darkness"),
              BookishRecordKey.authors: .list([.record(authorID)]),
              BookishRecordKey.source: .string(seedSourceID),
              BookishRecordKey.status: .string("To Read"),
              BookishRecordKey.format: .string("Paperback"),
              BookishRecordKey.note: .string("Seeded by the datastore harness"),
            ]
          )
        )
      )
    }

    if try await datastore.recordService.record(id: layoutID) == nil {
      try await datastore.mutationService.perform(
        .upsertRecord(
          BookishRecord(
            id: layoutID,
            kind: BookishRecordKind.layout,
            properties: [
              BookishRecordKey.title: .string("Bookish Book"),
              BookishRecordKey.fields: .list([
                .string(BookishRecordKey.title), .string(BookishRecordKey.authors),
                .string(BookishRecordKey.status), .string(BookishRecordKey.format),
                .string(BookishRecordKey.note),
              ]),
            ]
          )
        )
      )
    }

    if try await datastore.recordService.record(id: compactLayoutID) == nil {
      try await datastore.mutationService.perform(
        .upsertRecord(
          BookishRecord(
            id: compactLayoutID,
            kind: BookishRecordKind.layout,
            properties: [
              BookishRecordKey.title: .string("Compact Summary"),
              BookishRecordKey.fields: .list([
                .string(BookishRecordKey.title), .string(BookishRecordKey.name),
                .string(BookishRecordKey.status),
              ]),
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
      path: "BookishDatastore", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }

  private func updateLayoutSelection(using datastore: BookishDatastore) async throws {
    if selectedLayoutID == nil, try await datastore.recordService.record(id: layoutID) != nil {
      selectedLayoutID = layoutID
    }

    if let selectedLayoutID, try await datastore.recordService.record(id: selectedLayoutID) != nil {
      return
    }

    selectedLayoutID = layoutIDs.first
  }

  private var recordIndexQuery: RecordQuery {
    RecordQuery(
      predicate: .kind(BookishRecordKind.recordIndex),
      sort: [.property(BookishRecordKey.position), .property(BookishRecordKey.label), .id]
    )
  }

  private func refreshSelectedRecordIndex(using datastore: BookishDatastore) async throws {
    guard let selectedRecordIndex = navigation.selectedRecordIndex else {
      navigation.update(selectedRecordResult: nil)
      return
    }

    let result = try await datastore.recordQueryService.result(matching: selectedRecordIndex.query)
    navigation.update(selectedRecordResult: result)
  }

  private func selectRecordIndex(offset: Int) async {
    guard let datastore else {
      status = BookishHarnessError.notLoaded.localizedDescription
      return
    }

    do {
      if offset > 0 {
        navigation.selectNextRecordIndex()
      } else {
        navigation.selectPreviousRecordIndex()
      }
      try await refreshSelectedRecordIndex(using: datastore)
    } catch {
      report(error: error)
    }
  }

  private func seedRecordIndexes() throws -> [BookishRecord] {
    let entries: [(id: String, label: String, predicate: RecordPredicate)] = [
      ("all-records", "All Records", .all),
      ("records", "Records", .kind(BookishRecordKind.record)),
      ("books", "Books", .kind(BookishRecordKind.book)),
      ("people", "People", .kind(BookishRecordKind.person)),
      ("organisations", "Organisations", .kind(BookishRecordKind.organisation)),
      ("series", "Series", .kind(BookishRecordKind.series)),
      ("lists", "Lists", .kind(BookishRecordKind.list)),
      ("relationships", "Relationships", .kind(BookishRecordKind.relationship)),
      ("layouts", "Layouts", .kind(BookishRecordKind.layout)),
      ("record-indexes", "Record Indexes", .kind(BookishRecordKind.recordIndex)),
    ]

    return try entries.enumerated().map { position, entry in
      try BookishRecordIndex.record(
        id: BookishRecordID("datastore-index-\(entry.id)"),
        label: entry.label,
        position: position,
        query: RecordQuery(
          predicate: entry.predicate,
          sort: [.property(BookishRecordKey.title), .property(BookishRecordKey.name), .id]
        ),
        sourceID: seedSourceID
      )
    }
  }
}

private enum BookishHarnessError: LocalizedError {
  case notLoaded

  var errorDescription: String? {
    switch self {
    case .notLoaded:
      "The datastore is not loaded."
    }
  }
}
