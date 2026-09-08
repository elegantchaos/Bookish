// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

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

  /// The datastore service shared with navigation and other Bookish services.
  @ObservationIgnored let storageService: BookishStorageService

  /// The model-side interchange exporter used by the export sheet.
  @ObservationIgnored private let exportingService: BookishExportingService

  /// The model-side importer used by the import sheets and sample commands.
  @ObservationIgnored private let importingService: BookishImportingService

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
    exportingService = BookishExportingService(storageService: navigation.storageService)
    importingService = BookishImportingService(storageService: navigation.storageService)
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

    guard storageService.isLoaded else {
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
    await coordinateImport(fallbackDisplayName: BookishInterchangeImporter().descriptor.displayName) {
      try await self.importingService.importInterchange(from: url, reporting: $0)
    }
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
    await coordinateImport(fallbackDisplayName: BookishInterchangeImporter().descriptor.displayName) {
      try await self.importingService.importRecords(
        from: data,
        using: BookishInterchangeImporter(),
        reporting: $0
      )
    }
  }

  /// Imports records from a Delicious Library XML property-list file.
  public func importDeliciousLibrary(from url: URL) async {
    await coordinateImport(fallbackDisplayName: DeliciousLibraryImporter().descriptor.displayName) {
      try await self.importingService.importDeliciousLibrary(from: url, reporting: $0)
    }
  }

  /// Imports records from Delicious Library XML property-list data.
  public func importDeliciousLibrary(data: Data) async {
    await coordinateImport(fallbackDisplayName: DeliciousLibraryImporter().descriptor.displayName) {
      try await self.importingService.importRecords(
        from: data,
        using: DeliciousLibraryImporter(),
        reporting: $0
      )
    }
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

  /// Coordinates UI state while an import operation persists records.
  private func coordinateImport(
    fallbackDisplayName: String,
    perform import: (@escaping BookishImportEventReporter) async throws -> BookishImportSummary
  ) async {
    var firstRecord: BookishRecord?
    var displayName = fallbackDisplayName
    let clock = ContinuousClock()
    var lastProjectionRefresh = clock.now

    do {
      let summary = try await `import` { [self] event in
        switch event {
        case .started(let start):
          displayName = start.importer.displayName
          self.importProgress = BookishImportProgress(
            message: "Reading \(displayName)", completed: 0, total: start.total)
          self.status = "Reading \(displayName)"

        case .progress(let progress):
          self.importProgress = progress
          self.status = progress.message

        case .records(let records):
          firstRecord =
            firstRecord ?? records.first(where: { $0.kind == BookishRecordKind.book })
            ?? records.first
          if lastProjectionRefresh.duration(to: clock.now) >= .seconds(1) {
            try await self.refresh()
            lastProjectionRefresh = clock.now
          }

        case .diagnostic(let diagnostic):
          self.status = diagnostic

        case .finished:
          break
        }
      }

      try await refresh()
      if let firstRecord {
        navigation.select(recordID: firstRecord.id)
      }
      status =
        "Imported \(summary.recordCount) \(displayName) \(summary.recordCount == 1 ? "record" : "records")"
    } catch is CancellationError {
      status = "Import cancelled"
    } catch {
      status = error.localizedDescription
    }

    importProgress = nil
  }

  /// Exports the current materialised records as Bookish interchange JSON data.
  public func exportInterchangeData() async throws -> Data {
    try await exportingService.interchangeData(root: navigation.selectedRecordID)
  }

  /// Returns a record by resolving it from the record service.
  public func record(id: BookishRecordID) async throws -> BookishRecord? {
    try await storageService.record(id: id)
  }

  /// Returns the metadata record describing a catalogue kind, or the universal fallback.
  public func recordKindMetadata(for kind: String) async throws -> BookishRecord? {
    try await storageService.recordKindMetadata(for: kind)
  }

  /// Returns the observable result of resolving a query template against a host record.
  public func recordQueryResult(
    for template: RecordQueryTemplate,
    host: BookishRecord
  ) async throws -> RecordQueryResult {
    try await storageService.recordQueryResult(for: template, host: host)
  }

  /// Returns presentation records ordered from layout-specific to generic metadata.
  public func presentations(for kind: String, layout: BookishRecord? = nil) async throws
    -> [BookishRecord]
  {
    try await storageService.presentations(for: kind, layout: layout)
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
    try await storageService.mutations()
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

  /// Refreshes browser indexes, selected records, layouts, and compatible selection state.
  private func refresh() async throws {
    guard storageService.isLoaded else {
      return
    }

    let recordIndexResult = try await storageService.recordQueryResult(matching: recordIndexQuery)
    navigation.update(recordIndexResult: recordIndexResult)
    try await navigation.refreshSelectedRecordIndex()
    layouts = try await storageService.records(
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

    guard storageService.isLoaded else {
      return
    }

    if try await storageService.record(id: selectedLayoutID) == nil {
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
  BookishImportPresentation,
  BookishDatastoreMaintenance,
  BookishStatusReporting
{
}

extension BookishHarness: BookishRecordActionStore {
  /// Whether the datastore is available for record actions.
  var hasLoadedRecordStore: Bool { storageService.isLoaded }

  /// The record selected for an action.
  var selectedRecordID: BookishRecordID? { navigation.selectedRecordID }

  /// Applies one durable mutation to the datastore.
  func performRecordActionMutation(_ mutation: MutationRecord) async throws {
    try await storageService.perform(mutation)
  }

  /// Applies one remotely-originated mutation to the datastore.
  func receiveRemoteRecordActionMutation(_ mutation: MutationRecord) async throws {
    try await storageService.receiveRemoteMutation(mutation)
  }

  /// Refreshes observable browser state after an action.
  func refreshRecordActionState() async throws {
    try await refresh()
  }
}
