// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import BookishImporterSamples
import BookishRecord
import Foundation
import Observation

#if os(macOS)
  import AppKit
#endif

/// Updates browser settings that affect visible record indexes.
@MainActor
public protocol BookishBrowserSettings: AnyObject {
  /// Updates whether debug-only indexes are visible.
  func setShowsDebugIndexes(_ isVisible: Bool) async
}

/// Performs datastore maintenance actions requested by commands.
@MainActor
public protocol BookishDatastoreMaintenance {
  /// Whether records are available for interchange export.
  var hasExportableRecords: Bool { get }
  /// Requests interchange export.
  func requestInterchangeExport() async
}

/// Presents import controls requested by commands.
@MainActor
public protocol BookishImportPresentation {
  /// Requests an interchange file import.
  func requestInterchangeImport()
  /// Requests a Delicious Library file import.
  func requestDeliciousLibraryImport()
  /// Requests access to the Kindle library database folder.
  func requestKindleLibraryImport()
  /// Imports a bundled Delicious Library sample.
  func importDeliciousLibrary(sample: DeliciousLibrarySample) async
  /// Imports a selected interchange file.
  func importInterchange(from url: URL) async
  /// Imports a selected Delicious Library export.
  func importDeliciousLibrary(from url: URL) async
  /// Imports a selected Kindle library database folder.
  func importKindleLibrary(from url: URL) async
}

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
  public var hasExportableRecords: Bool { !navigation.recordIDs.isEmpty }

  /// Increments whenever the record projection is refreshed.
  public private(set) var revision = 0

  /// Whether the interchange import file picker is visible.
  public var isImportingInterchange = false

  /// Whether the Delicious Library import file picker is visible.
  public var isImportingDeliciousLibrary = false

  /// The imported records awaiting user review.
  public private(set) var pendingImportPlan: BookishImportPlan?

  @ObservationIgnored private var pendingImportDisplayName = "Import"

  /// Whether the import review sheet is visible.
  public var isReviewingImport = false

  /// Whether the interchange export file picker is visible.
  public var isExportingInterchange = false

  /// The document currently being exported.
  public var interchangeExportDocument = BookishInterchangeDocument()

  /// Whether debug-only indexes are included in the browser.
  public let defaultShowsDebugIndexes: Bool

  /// Whether debug-only indexes are currently included in the browser.
  public private(set) var showsDebugIndexes: Bool

  /// The model-side interchange exporter used by the export sheet.
  @ObservationIgnored private let exportingService: any BookishExporting

  /// The model-side importer used by the import sheets and sample commands.
  @ObservationIgnored private let importingService: any BookishImporting

  /// Creates UI state backed by the supplied Bookish services.
  public init(
    navigation: BookishNavigationService,
    presentation: BookishPresentationService,
    statusService: BookishStatusService,
    importingService: any BookishImporting,
    exportingService: any BookishExporting,
    defaultShowsDebugIndexes: Bool = false
  ) {
    self.navigation = navigation
    self.statusService = statusService
    self.presentation = presentation
    self.exportingService = exportingService
    self.importingService = importingService
    self.defaultShowsDebugIndexes = defaultShowsDebugIndexes
    self.showsDebugIndexes = defaultShowsDebugIndexes
    navigation.setRecordIndexSelectionHandler { [weak presentation, weak navigation] in
      try await presentation?.refresh(for: navigation?.selectedRecordIndex)
    }
  }

  /// Updates whether debug-only indexes are available in the browser.
  public func setShowsDebugIndexes(_ showsDebugIndexes: Bool) async {
    guard self.showsDebugIndexes != showsDebugIndexes else {
      return
    }

    self.showsDebugIndexes = showsDebugIndexes

    do {
      try await refreshBrowser()
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

  /// Opens the system permission picker at Kindle's database directory.
  public func requestKindleLibraryImport() {
    #if os(macOS)
      let panel = NSOpenPanel()
      panel.canChooseDirectories = true
      panel.canChooseFiles = false
      panel.canCreateDirectories = false
      panel.allowsMultipleSelection = false
      panel.prompt = "Grant Access"
      panel.message = "Select the Protected folder containing BookData.sqlite."
      panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        .appending(path: "Library/Containers/com.amazon.Lassen/Data/Library/Protected")
      panel.begin { [weak self] response in
        guard response == .OK, let url = panel.url else { return }
        Task { @MainActor [weak self] in await self?.importKindleLibrary(from: url) }
      }
    #endif
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

  /// Imports new Kindle books from a user-selected folder.
  public func importKindleLibrary(from url: URL) async {
    await coordinateImport(fallbackDisplayName: KindleLibraryImporter().descriptor.displayName) {
      try await self.importingService.importKindleLibrary(from: url, reporting: $0)
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

  /// Collects an import proposal and presents it for review.
  private func coordinateImport(
    fallbackDisplayName: String,
    perform import: (@escaping BookishImportEventReporter) async throws -> BookishImportPlan
  ) async {
    var displayName = fallbackDisplayName

    do {
      let plan = try await `import` { [self] event in
        switch event {
        case .started(let start):
          displayName = start.importer.displayName
          self.statusService.report(
            progress: BookishImportProgress(
              message: "Reading \(displayName)", completed: 0, total: start.total))

        case .progress(let progress):
          self.statusService.report(progress: progress)

        case .records:
          break

        case .diagnostic(let diagnostic):
          self.statusService.report(message: diagnostic)

        case .finished:
          break
        }
      }

      pendingImportPlan = plan
      pendingImportDisplayName = displayName
      isReviewingImport = true
      statusService.report(
        message:
          "Review \(plan.entries.count) \(displayName) \(plan.entries.count == 1 ? "record" : "records")"
      )
    } catch is CancellationError {
      statusService.report(message: "Import cancelled")
    } catch {
      statusService.report(error: error)
    }

    statusService.clearImportProgress()
  }

  /// Applies the reviewed proposal and refreshes the visible catalogue.
  public func applyPendingImport(choices: [BookishRecordID: BookishImportChoice]) async {
    guard let plan = pendingImportPlan else { return }
    do {
      let resolution = try await importingService.apply(plan, choices: choices)
      pendingImportPlan = nil
      isReviewingImport = false
      try await refreshBrowser()
      if let firstBook = resolution.records.first(where: { $0.kind == BookishRecordKind.book })
        ?? resolution.records.first
      {
        navigation.select(recordID: firstBook.id)
      }
      let count = resolution.records.count
      statusService.report(
        message:
          "Imported \(count) \(pendingImportDisplayName) \(count == 1 ? "record" : "records")")
    } catch {
      statusService.report(error: error)
    }
  }

  /// Discards an import proposal without changing the catalogue.
  public func cancelPendingImport() {
    guard pendingImportPlan != nil else { return }
    pendingImportPlan = nil
    isReviewingImport = false
    statusService.report(message: "Import cancelled")
  }

  /// Exports the current materialised records as Bookish interchange JSON data.
  public func exportInterchangeData() async throws -> Data {
    try await exportingService.interchangeData(root: navigation.selectedRecordID)
  }

  /// Refreshes browser indexes, selected records, layouts, and compatible selection state.
  public func refreshBrowser() async throws {
    try await navigation.refreshRecordIndexes(showsDebugIndexes: showsDebugIndexes)
    try await presentation.refresh(for: navigation.selectedRecordIndex)
    revision += 1
  }
}

extension BookishUIStateService:
  BookishImportPresentation,
  BookishDatastoreMaintenance,
  BookishBrowserSettings
{
}

extension BookishUIStateService: BookishRecordActionState {
  /// The record selected for an action.
  var selectedRecordID: BookishRecordID? { navigation.selectedRecordID }

  /// Refreshes observable browser state after an action.
  func refreshRecordActionState() async throws {
    try await refreshBrowser()
  }
}
