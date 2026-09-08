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

/// Owns global Bookish UI state and coordinates UI-triggered work across services.
@MainActor
@Observable
public final class BookishUIStateService {
  /// The navigation and routing service used by the datastore browser.
  @ObservationIgnored public let navigation: BookishNavigationService

  /// The layout and property-presentation service used by the browser UI.
  @ObservationIgnored public let presentation: BookishPresentationService

  /// The status service used to present progress, messages, and errors.
  @ObservationIgnored public let statusService: BookishStatusService

  /// Whether an interchange export has records to write.
  public var hasExportableRecords: Bool { navigation.recordIDs.isEmpty == false }

  /// Increments whenever the record projection is refreshed.
  public private(set) var revision = 0

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

  /// The datastore service shared with navigation and other Bookish services.
  @ObservationIgnored let storageService: BookishStorageService

  /// The model-side interchange exporter used by the export sheet.
  @ObservationIgnored private let exportingService: BookishExportingService

  /// The model-side importer used by the import sheets and sample commands.
  @ObservationIgnored private let importingService: BookishImportingService

  /// Creates UI state backed by the supplied Bookish services.
  public init(
    navigation: BookishNavigationService,
    presentation: BookishPresentationService,
    statusService: BookishStatusService,
    importingService: BookishImportingService,
    exportingService: BookishExportingService,
    defaultShowsDebugIndexes: Bool = false
  ) {
    self.navigation = navigation
    self.statusService = statusService
    storageService = navigation.storageService
    self.presentation = presentation
    self.exportingService = exportingService
    self.importingService = importingService
    self.defaultShowsDebugIndexes = defaultShowsDebugIndexes
    self.showsDebugIndexes = defaultShowsDebugIndexes
    navigation.setRecordIndexSelectionHandler { [weak presentation, weak navigation] in
      try await presentation?.refresh(for: navigation?.selectedRecordIndex)
    }
  }

  /// Loads, seeds, and refreshes the datastore.
  public func load() async {
    do {
      try await storageService.load()
      try await refresh()
      statusService.report(message: "Ready")
    } catch {
      statusService.report(error: error)
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
      statusService.report(error: error)
    }
  }

  /// Imports records from a Bookish interchange JSON file.
  public func importInterchange(from url: URL) async {
    await coordinateImport(fallbackDisplayName: BookishInterchangeImporter().descriptor.displayName)
    {
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
      statusService.report(error: error)
    }
  }

  /// Handles successful completion of the interchange export panel.
  public func didExportInterchange() {
    statusService.report(message: "Exported interchange file")
  }

  /// Removes every stored record and mutation, then restores the seed records.
  public func reset() async {
    do {
      resetProjectionState()
      try await storageService.reset()
      try await refresh()
      statusService.report(message: "Reset datastore")
    } catch {
      statusService.report(error: error)
    }
  }

  /// Rebuilds the materialised record projection from durable mutations.
  public func rebuildRecordProjection() async {
    do {
      resetProjectionState()
      try await storageService.rebuildRecordProjection()
      statusService.report(message: "Rebuilt record store")
    } catch {
      statusService.report(error: error)
    }
  }

  /// Imports records from Bookish interchange JSON data.
  public func importInterchange(data: Data) async {
    await coordinateImport(fallbackDisplayName: BookishInterchangeImporter().descriptor.displayName)
    {
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
      statusService.report(error: error)
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
          self.statusService.report(
            progress: BookishImportProgress(
              message: "Reading \(displayName)", completed: 0, total: start.total))

        case .progress(let progress):
          self.statusService.report(progress: progress)

        case .records(let records):
          firstRecord =
            firstRecord ?? records.first(where: { $0.kind == BookishRecordKind.book })
            ?? records.first
          if lastProjectionRefresh.duration(to: clock.now) >= .seconds(1) {
            try await self.refresh()
            lastProjectionRefresh = clock.now
          }

        case .diagnostic(let diagnostic):
          self.statusService.report(message: diagnostic)

        case .finished:
          break
        }
      }

      try await refresh()
      if let firstRecord {
        navigation.select(recordID: firstRecord.id)
      }
      statusService.report(
        message:
          "Imported \(summary.recordCount) \(displayName) \(summary.recordCount == 1 ? "record" : "records")"
      )
    } catch is CancellationError {
      statusService.report(message: "Import cancelled")
    } catch {
      statusService.report(error: error)
    }

    statusService.clearImportProgress()
  }

  /// Exports the current materialised records as Bookish interchange JSON data.
  public func exportInterchangeData() async throws -> Data {
    try await exportingService.interchangeData(root: navigation.selectedRecordID)
  }

  /// Refreshes browser indexes, selected records, layouts, and compatible selection state.
  private func refresh() async throws {
    guard storageService.isLoaded else {
      return
    }

    let recordIndexResult = try await storageService.recordQueryResult(matching: recordIndexQuery)
    navigation.update(recordIndexResult: recordIndexResult)
    try await navigation.refreshSelectedRecordIndex()
    try await presentation.refresh(for: navigation.selectedRecordIndex)
    revision += 1
  }

  /// Clears UI state tied to the current materialised projection.
  private func resetProjectionState() {
    navigation.reset()
    presentation.reset()
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

extension BookishUIStateService:
  BookishImportPresentation,
  BookishDatastoreMaintenance
{
}

extension BookishUIStateService: BookishRecordActionState {
  /// The record selected for an action.
  var selectedRecordID: BookishRecordID? { navigation.selectedRecordID }

  /// Refreshes observable browser state after an action.
  func refreshRecordActionState() async throws {
    try await refresh()
  }
}
