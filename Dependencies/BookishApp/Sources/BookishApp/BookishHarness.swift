// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

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

  /// The identifiers of layout records compatible with the selected browser index.
  public var compatibleLayoutIDs: [BookishRecordID] {
    compatibleLayouts.map(\.id)
  }

  /// Whether an interchange export has records to write.
  public var hasExportableRecords: Bool { navigation.recordIDs.isEmpty == false }

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

  /// Whether debug-only indexes are included in the browser.
  public let defaultShowsDebugIndexes: Bool

  /// Whether debug-only indexes are currently included in the browser.
  public private(set) var showsDebugIndexes: Bool

  /// The universal layout used when no explicit layout is selected.
  private let fallbackLayoutID = BookishRecordID("datastore-all-fields-layout")

  /// The universal property presentation used after more-specific presentations.
  private let fallbackPresentationID = BookishRecordID("presentation.type.*")

  /// The datastore service shared with navigation and other Bookish services.
  @ObservationIgnored let storageService: BookishStorageService

  /// The loaded datastore used by harness responsibilities that have not yet moved into services.
  private var datastore: BookishDatastore? {
    storageService.datastore
  }

  /// The loaded layout records used to derive compatible layout choices.
  private var layouts: [BookishRecord] = []

  /// Creates an empty harness ready to load the datastore.
  public init(
    directoryURL: URL? = nil,
    navigation: BookishNavigationService = BookishNavigationService(),
    defaultShowsDebugIndexes: Bool = false
  ) {
    self.navigation = navigation
    storageService = navigation.storageService
    storageService.configure(directoryURL: directoryURL)
    self.defaultShowsDebugIndexes = defaultShowsDebugIndexes
    self.showsDebugIndexes = defaultShowsDebugIndexes
    navigation.setRecordIndexSelectionHandler { [weak self] in
      try await self?.updateLayoutSelection()
    }
  }

  /// Loads, seeds, and refreshes the datastore.
  public func load() async {
    do {
      try await storageService.load()
      try await refresh()
      status = "Ready"
    } catch {
      status = error.localizedDescription
    }
  }

  /// Updates whether debug-only indexes are available in the browser.
  public func setShowsDebugIndexes(_ showsDebugIndexes: Bool) async {
    guard self.showsDebugIndexes != showsDebugIndexes else {
      return
    }

    self.showsDebugIndexes = showsDebugIndexes

    guard datastore != nil else {
      return
    }

    do {
      try await refresh()
    } catch {
      report(error: error)
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

  /// Removes every stored record and mutation, then restores the seed records.
  public func reset() async {
    do {
      resetProjectionState()
      try await storageService.reset()
      try await refresh()
      status = "Reset datastore"
    } catch {
      status = error.localizedDescription
    }
  }

  /// Rebuilds the materialised record projection from durable mutations.
  public func rebuildRecordProjection() async {
    do {
      resetProjectionState()
      try await storageService.rebuildRecordProjection()
      status = "Rebuilt record store"
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
    guard datastore != nil else {
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
          try await storageService.upsert(records: records)
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

  /// Returns the metadata record describing a catalogue kind, or the universal fallback.
  public func recordKindMetadata(for kind: String) async throws -> BookishRecord? {
    let metadataID = BookishRecordID("metadata.type.\(kind)")
    if let metadata = try await record(id: metadataID) {
      return metadata
    }

    return try await record(id: BookishRecordID("metadata.type.*"))
  }

  /// Returns the observable result of resolving a query template against a host record.
  public func recordQueryResult(
    for template: RecordQueryTemplate,
    host: BookishRecord
  ) async throws -> RecordQueryResult {
    guard let datastore else {
      throw BookishHarnessError.notLoaded
    }

    return try await datastore.recordQueryService.result(matching: template.resolve(for: host))
  }

  /// Returns presentation records ordered from layout-specific to generic metadata.
  public func presentations(for kind: String, layout: BookishRecord? = nil) async throws
    -> [BookishRecord]
  {
    var presentations: [BookishRecord] = []

    if let presentationID = layout?.record(BookishRecordKey.presentation) {
      if let presentation = try await record(id: presentationID) {
        presentations.append(presentation)
      }
    }

    if let metadata = try await recordKindMetadata(for: kind),
      let presentationID = metadata.record(BookishRecordKey.presentation),
      let presentation = try await record(id: presentationID)
    {
      presentations.append(presentation)
    }

    if presentations.contains(where: { $0.id == fallbackPresentationID }) == false,
      let presentation = try await record(id: fallbackPresentationID)
    {
      presentations.append(presentation)
    }

    return presentations
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
    guard let datastore else {
      throw BookishHarnessError.notLoaded
    }

    return try await datastore.mutationStore.mutations()
  }

  /// Returns the selected layout by resolving it from the record service.
  public func selectedLayout() async throws -> BookishRecord? {
    let layoutID = selectedLayoutID ?? navigation.selectedRecordIndex?.layoutID ?? fallbackLayoutID
    return try await record(id: layoutID)
  }

  /// Returns the explicit layout selection or the type-specific layout for a displayed record.
  public func layout(for record: BookishRecord) async throws -> BookishRecord? {
    if selectedLayoutID != nil {
      return try await selectedLayout()
    }

    if let typeSpecificLayout = layouts.first(where: { layout in
      layout.bool(BookishRecordKey.isSection) != true
        && layout.strings(BookishRecordKey.types)?.contains(record.kind) == true
    }) {
      return typeSpecificLayout
    }

    return try await selectedLayout()
  }

  /// Returns the local directory used for datastore files.
  public func localDatastoreDirectory() throws -> URL {
    try storageService.localDatastoreDirectory()
  }

  /// Reports an arbitrary user-facing message.
  public func report(message: String) {
    status = message
  }

  /// Reports an arbitrary user-facing error.
  public func report(error: Error) {
    status = error.localizedDescription
  }

  /// Reads a security-scoped file and imports its data with the supplied importer.
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

  /// Refreshes browser indexes, selected records, layouts, and compatible selection state.
  private func refresh() async throws {
    guard let datastore else {
      return
    }

    let recordIndexResult = try await datastore.recordQueryService.result(
      matching: recordIndexQuery)
    navigation.update(recordIndexResult: recordIndexResult)
    try await navigation.refreshSelectedRecordIndex()
    layouts = try await datastore.recordService.records(
      matching: RecordQuery(
        predicate: .kind(BookishRecordKind.layout),
        sort: [.property(BookishRecordKey.name), .id]
      ))
    layoutIDs = layouts.filter { $0.bool(BookishRecordKey.isSection) != true }.map(\.id)
    revision += 1
    try await updateLayoutSelection()
  }

  /// Clears UI state tied to the current materialised projection.
  private func resetProjectionState() {
    navigation.reset()
    selectedLayoutID = nil
    layouts = []
    layoutIDs = []
  }

  /// Clears a selected layout that is missing or incompatible with the active index.
  private func updateLayoutSelection() async throws {
    guard let selectedLayoutID else {
      return
    }

    guard let datastore else {
      return
    }

    if try await datastore.recordService.record(id: selectedLayoutID) == nil {
      self.selectedLayoutID = nil
      return
    }

    if !compatibleLayoutIDs.contains(selectedLayoutID) {
      self.selectedLayoutID = nil
    }
  }

  /// The layouts compatible with the active browser index's advisory kinds.
  private var compatibleLayouts: [BookishRecord] {
    guard let selectedRecordIndex = navigation.selectedRecordIndex else {
      return layouts
    }

    return layouts.filter { layout in
      layout.bool(BookishRecordKey.isSection) != true
        && layout.matchesAnyType(in: selectedRecordIndex.types)
    }
  }

  /// The query that loads visible browser index records.
  private var recordIndexQuery: RecordQuery {
    let predicate: RecordPredicate
    if showsDebugIndexes {
      predicate = .kind(BookishRecordKind.index)
    } else {
      predicate = .and([
        .kind(BookishRecordKind.index),
        .not(.property(BookishRecordKey.debugOnly, equals: .bool(true))),
      ])
    }

    return RecordQuery(
      predicate: predicate,
      sort: [.property(BookishRecordKey.position), .property(BookishRecordKey.name), .id]
    )
  }

}

extension BookishHarness:
  BookishImporting,
  BookishDatastoreMaintenance,
  BookishStatusReporting
{
}

extension BookishHarness: BookishRecordActionStore {
  /// Whether the datastore is available for record actions.
  var hasLoadedRecordStore: Bool { datastore != nil }

  /// The record selected for an action.
  var selectedRecordID: BookishRecordID? { navigation.selectedRecordID }

  /// Applies one durable mutation to the datastore.
  func performRecordActionMutation(_ mutation: MutationRecord) async throws {
    guard let datastore else {
      throw BookishHarnessError.notLoaded
    }

    try await datastore.mutationService.perform(mutation.operation)
  }

  /// Applies one remotely-originated mutation to the datastore.
  func receiveRemoteRecordActionMutation(_ mutation: MutationRecord) async throws {
    guard let datastore else {
      throw BookishHarnessError.notLoaded
    }

    try await datastore.mutationService.receiveRemoteMutation(mutation)
  }

  /// Refreshes observable browser state after an action.
  func refreshRecordActionState() async throws {
    try await refresh()
  }
}
