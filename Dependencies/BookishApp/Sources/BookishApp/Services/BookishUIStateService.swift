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

/// Presents the iOS settings sheet through a command.
@MainActor
public protocol BookishSettingsPresentation: AnyObject {
  /// Opens the settings sheet.
  func openSettings()
  /// Closes the settings sheet.
  func closeSettings()
}

/// Creates user records and reveals them in a suitable browser index.
@MainActor
public protocol BookishRecordCreation: AnyObject {
  /// Whether a visible index can show a new record of this type.
  func canCreate(_ type: BookishNewRecordType) -> Bool
  /// Creates and selects a record of the requested type.
  func create(_ type: BookishNewRecordType) async throws
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
  /// Whether a prepared import can be applied.
  var canApplyPendingImport: Bool { get }
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
  /// Applies the current review choices.
  func applyPendingImport() async
  /// Discards the current proposal.
  func cancelPendingImport()
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

  /// Whether the interchange import file picker is visible.
  public var isImportingInterchange = false

  /// Whether the iOS settings sheet is visible.
  public var isShowingSettings = false

  /// Whether the Delicious Library import file picker is visible.
  public var isImportingDeliciousLibrary = false

  /// The imported records awaiting user review.
  public private(set) var pendingImportPlan: BookishImportPlan?

  /// Choices for the pending proposal, initially favouring existing records.
  public private(set) var importChoices: [BookishRecordID: BookishImportChoice] = [:]

  /// The last applied import, shown in the Import workflow.
  public private(set) var lastImportResult: BookishImportWorkflowResult?

  /// Whether an importer is still reading its source.
  public private(set) var isPreparingImport = false

  /// Whether a reviewed proposal is being written to storage.
  public private(set) var isApplyingImport = false

  /// A source-reading or apply error shown in the Import workflow.
  public private(set) var importErrorMessage: String?

  /// Whether all review choices are ready to apply.
  public var canApplyPendingImport: Bool {
    guard let pendingImportPlan, !isApplyingImport else { return false }
    return pendingImportPlan.reviewEntries.allSatisfy { importChoices[$0.id] != nil }
  }

  @ObservationIgnored private var pendingImportDisplayName = "Import"

  /// Whether the interchange export file picker is visible.
  public var isExportingInterchange = false

  /// The document currently being exported.
  public var interchangeExportDocument = BookishInterchangeDocument()

  /// Whether debug-only indexes are included in the browser.
  public let defaultShowsDebugIndexes: Bool

  /// Whether debug-only indexes are currently included in the browser.
  public private(set) var showsDebugIndexes: Bool

  /// The model-side interchange exporter used by the export sheet.
  @ObservationIgnored private let exportingService: any BookishExportingService.API

  /// The model-side importer used by the import sheets and sample commands.
  @ObservationIgnored private let importingService: any BookishImportingService.API

  /// Creates UI state backed by the supplied Bookish services.
  public init(
    navigation: BookishNavigationService,
    presentation: BookishPresentationService,
    statusService: BookishStatusService,
    importingService: any BookishImportingService.API,
    exportingService: any BookishExportingService.API,
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
    guard showImportWorkflowIfReady() else { return }
    isImportingInterchange = true
  }

  /// Opens settings from the iOS toolbar.
  public func openSettings() {
    isShowingSettings = true
  }

  /// Closes the iOS settings sheet.
  public func closeSettings() {
    isShowingSettings = false
  }

  /// Returns whether a standard library index accepts the requested type.
  public func canCreate(_ type: BookishNewRecordType) -> Bool {
    navigation.storageService.isLoaded && creationIndex(for: newRecord(of: type)) != nil
  }

  /// Persists a new record, switches to its index, and selects it.
  public func create(_ type: BookishNewRecordType) async throws {
    let record = newRecord(of: type)
    guard let targetIndex = creationIndex(for: record) else {
      throw BookishRecordCreationError.noIndex(type)
    }

    try await navigation.storageService.upsert(records: [record])
    try await navigation.select(recordIndexID: targetIndex.id)
    try await navigation.setRecordNameFilter("")
    try await refreshBrowser()
    navigation.select(recordID: record.id)
  }

  /// Builds the initial record before checking index query compatibility.
  private func newRecord(of type: BookishNewRecordType) -> BookishRecord {
    BookishRecord(
      id: BookishRecordID(UUID().uuidString),
      kind: type.rawValue,
      properties: [BookishRecordKey.name: .string(type.initialName)]
    )
  }

  /// Finds a configured index whose query will include the new record.
  private func creationIndex(for record: BookishRecord) -> BookishRecordIndex? {
    guard let type = BookishNewRecordType(rawValue: record.kind) else { return nil }
    let indexes = navigation.libraryIndexes
    if let selectedIndex = navigation.selectedRecordIndex,
      !selectedIndex.isDebugOnly,
      selectedIndex.newRecordTypes.contains(type),
      selectedIndex.query?.predicate.matches(record) == true
    {
      return selectedIndex
    }
    return indexes.first {
      $0.newRecordTypes.contains(type) && $0.query?.predicate.matches(record) == true
    }
  }

  /// Requests a Delicious Library file import.
  public func requestDeliciousLibraryImport() {
    guard showImportWorkflowIfReady() else { return }
    isImportingDeliciousLibrary = true
  }

  /// Opens the system permission picker at Kindle's database directory.
  public func requestKindleLibraryImport() {
    guard showImportWorkflowIfReady() else { return }
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

  /// Selects Import and preserves an existing proposal until it is applied or cancelled.
  private func showImportWorkflowIfReady() -> Bool {
    navigation.select(mainSection: .importing)
    guard pendingImportPlan == nil, !isPreparingImport, !isApplyingImport else {
      statusService.report(message: "Finish or cancel the current import first")
      return false
    }
    return true
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
    guard showImportWorkflowIfReady() else { return }
    do {
      await importDeliciousLibrary(
        from: try BookishImporterSamples.deliciousLibraryURL(for: sample))
    } catch {
      importErrorMessage = error.localizedDescription
      statusService.report(error: error)
    }
  }

  /// Collects an import proposal and presents it for review.
  private func coordinateImport(
    fallbackDisplayName: String,
    perform import: (@escaping BookishImportEventReporter) async throws -> BookishImportPlan
  ) async {
    var displayName = fallbackDisplayName
    guard showImportWorkflowIfReady() else { return }
    pendingImportPlan = nil
    importChoices = [:]
    lastImportResult = nil
    importErrorMessage = nil
    isPreparingImport = true
    defer { isPreparingImport = false }

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
      importChoices = plan.defaultChoices
      pendingImportDisplayName = displayName
      statusService.report(
        message:
          "Review \(plan.entries.count) \(displayName) \(plan.entries.count == 1 ? "record" : "records")"
      )
    } catch is CancellationError {
      statusService.report(message: "Import cancelled")
    } catch {
      importErrorMessage = error.localizedDescription
      statusService.report(error: error)
    }

    statusService.clearImportProgress()
  }

  /// Applies the reviewed proposal and refreshes the visible catalogue.
  public func applyPendingImport(choices: [BookishRecordID: BookishImportChoice]) async {
    guard let plan = pendingImportPlan, !isApplyingImport else { return }
    isApplyingImport = true
    defer { isApplyingImport = false }
    do {
      let resolution = try await importingService.apply(plan, choices: choices)
      pendingImportPlan = nil
      importChoices = [:]
      importErrorMessage = nil
      lastImportResult = BookishImportWorkflowResult(
        sourceName: pendingImportDisplayName, importedRecords: resolution.records,
        skippedCount: plan.skippedCount,
        reusedCount: choices.values.filter {
          switch $0 {
          case .keepExisting, .useExisting: true
          case .create, .replaceExisting: false
          }
        }.count)
      try await refreshBrowser()
      let count = resolution.records.count
      statusService.report(
        message:
          "Imported \(count) \(pendingImportDisplayName) \(count == 1 ? "record" : "records")")
    } catch {
      importErrorMessage = error.localizedDescription
      statusService.report(error: error)
    }
  }

  /// Applies the choices currently shown in the Import workflow.
  public func applyPendingImport() async {
    await applyPendingImport(choices: importChoices)
  }

  /// Sets one review choice.
  public func setImportChoice(_ choice: BookishImportChoice, for id: BookishRecordID) {
    guard pendingImportPlan?.reviewEntries.contains(where: { $0.id == id }) == true else { return }
    importChoices[id] = choice
  }

  /// Sets the preference for selected review entries in one operation.
  public func setImportChoices(
    for ids: Set<BookishRecordID>, preferring preference: BookishImportPreference
  ) {
    guard let pendingImportPlan else { return }
    importChoices.merge(pendingImportPlan.choices(for: ids, preferring: preference)) { _, new in
      new
    }
  }

  /// Discards an import proposal without changing the catalogue.
  public func cancelPendingImport() {
    guard pendingImportPlan != nil else { return }
    pendingImportPlan = nil
    importChoices = [:]
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
    navigation.storageService.didRefreshRecords()
  }
}

extension BookishUIStateService:
  BookishImportPresentation,
  BookishDatastoreMaintenance,
  BookishBrowserSettings,
  BookishSettingsPresentation,
  BookishRecordCreation
{
}

/// Explains why a New command cannot find a browser destination.
enum BookishRecordCreationError: LocalizedError {
  /// No library index is configured to show the requested type.
  case noIndex(BookishNewRecordType)

  /// The error shown by the app's command failure reporter.
  var errorDescription: String? {
    switch self {
    case .noIndex(let type): "No index can show a new \(type.menuName.lowercased())."
    }
  }
}

extension BookishUIStateService: BookishRecordActionState {
  /// The record selected for an action.
  var selectedRecordID: BookishRecordID? { navigation.selectedRecordID }

  /// Refreshes observable browser state after an action.
  func refreshRecordActionState() async throws {
    try await refreshBrowser()
  }
}
