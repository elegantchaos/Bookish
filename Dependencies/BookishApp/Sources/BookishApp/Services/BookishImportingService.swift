// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 25/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishDatastore
import BookishImporter
import BookishImporterSamples
import BookishRecord
import Commands
import Foundation
import Observation

#if os(macOS)
  import AppKit
#endif

/// Receives importer lifecycle events while building a proposal.
public typealias BookishImportEventReporter = @MainActor (BookishImportEvent) async throws -> Void

/// Owns the Import workflow: reading a source, reviewing its proposal, and applying it to storage.
@MainActor
public final class BookishImportingService {
  /// Starts, applies, and cancels imports requested by commands.
  @MainActor
  public protocol API: AnyObject {
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

  @MainActor
  public protocol Provider: CommandCentre {
    var importingService: any API { get }
  }

  @MainActor
  @Observable
  public final class State {
    /// Whether the interchange import file picker is visible.
    public var isImportingInterchange = false

    /// Whether the Delicious Library import file picker is visible.
    public var isImportingDeliciousLibrary = false

    /// The imported records awaiting user review.
    public fileprivate(set) var pendingImportPlan: BookishImportPlan?

    /// Choices for the pending proposal, initially favouring existing records.
    public fileprivate(set) var importChoices: [BookishRecordID: BookishImportChoice] = [:]

    /// The last applied import, shown in the Import workflow.
    public fileprivate(set) var lastImportResult: BookishImportWorkflowResult?

    /// Whether an importer is still reading its source.
    public fileprivate(set) var isPreparingImport = false

    /// Whether a reviewed proposal is being written to storage.
    public fileprivate(set) var isApplyingImport = false

    /// A source-reading or apply error shown in the Import workflow.
    public fileprivate(set) var importErrorMessage: String?

    fileprivate init() {}

    /// Whether all review choices are ready to apply.
    public var canApplyPendingImport: Bool {
      guard let pendingImportPlan, !isApplyingImport else { return false }
      return pendingImportPlan.reviewEntries.allSatisfy { importChoices[$0.id] != nil }
    }

    /// Sets one review choice.
    public func setImportChoice(_ choice: BookishImportChoice, for id: BookishRecordID) {
      guard pendingImportPlan?.reviewEntries.contains(where: { $0.id == id }) == true else {
        return
      }
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
  }

  public let state = State()

  /// The display name of the source that produced the pending proposal.
  private var pendingImportDisplayName = "Import"

  /// The storage service that owns durable import mutations.
  private let storageService: BookishStorageService

  /// The navigation service used to show the Import workflow.
  private let navigation: any BookishNavigationService.API

  /// The browser service used to refresh indexes after an import is applied.
  private let browser: any BookishBrowserService.API

  /// The status service used to report import progress and outcomes.
  private let statusService: BookishStatusService

  /// Creates an import workflow backed by the supplied services.
  init(
    storageService: BookishStorageService,
    navigation: any BookishNavigationService.API,
    browser: any BookishBrowserService.API,
    statusService: BookishStatusService
  ) {
    self.storageService = storageService
    self.navigation = navigation
    self.browser = browser
    self.statusService = statusService
  }

  /// Applies the reviewed proposal and refreshes the visible catalogue.
  func applyPendingImport(choices: [BookishRecordID: BookishImportChoice]) async {
    guard let plan = state.pendingImportPlan, !state.isApplyingImport else { return }
    state.isApplyingImport = true
    defer { state.isApplyingImport = false }
    do {
      let resolution = try await apply(plan, choices: choices)
      state.pendingImportPlan = nil
      state.importChoices = [:]
      state.importErrorMessage = nil
      state.lastImportResult = BookishImportWorkflowResult(
        sourceName: pendingImportDisplayName, importedRecords: resolution.records,
        skippedCount: plan.skippedCount,
        reusedCount: choices.values.filter {
          switch $0 {
          case .keepExisting, .useExisting: true
          case .create, .replaceExisting: false
          }
        }.count)
      // TEMPORARY: refreshes the browser so imported records appear; remove when
      // views observe their records and queries.
      try await browser.refresh()
      let count = resolution.records.count
      statusService.report(
        message:
          "Imported \(count) \(pendingImportDisplayName) \(count == 1 ? "record" : "records")")
    } catch {
      state.importErrorMessage = error.localizedDescription
      statusService.report(error: error)
    }
  }

  /// Imports records from Bookish interchange JSON data.
  func importInterchange(data: Data) async {
    await coordinateImport(fallbackDisplayName: BookishInterchangeImporter().descriptor.displayName)
    {
      try await self.importRecords(
        from: data,
        using: BookishInterchangeImporter(),
        reporting: $0
      )
    }
  }

  /// Imports records from Delicious Library XML property-list data.
  func importDeliciousLibrary(data: Data) async {
    await coordinateImport(fallbackDisplayName: DeliciousLibraryImporter().descriptor.displayName) {
      try await self.importRecords(
        from: data,
        using: DeliciousLibraryImporter(),
        reporting: $0
      )
    }
  }
}

extension BookishImportingService: BookishImportingService.API {
  public var canApplyPendingImport: Bool { state.canApplyPendingImport }

  public func requestInterchangeImport() {
    guard showImportWorkflowIfReady() else { return }
    state.isImportingInterchange = true
  }

  public func requestDeliciousLibraryImport() {
    guard showImportWorkflowIfReady() else { return }
    state.isImportingDeliciousLibrary = true
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

  /// Imports one of the Delicious Library sample files bundled with Bookish.
  public func importDeliciousLibrary(sample: DeliciousLibrarySample) async {
    guard showImportWorkflowIfReady() else { return }
    do {
      await importDeliciousLibrary(
        from: try BookishImporterSamples.deliciousLibraryURL(for: sample))
    } catch {
      state.importErrorMessage = error.localizedDescription
      statusService.report(error: error)
    }
  }

  public func importInterchange(from url: URL) async {
    await coordinateImport(fallbackDisplayName: BookishInterchangeImporter().descriptor.displayName)
    {
      try await self.importInterchange(from: url, reporting: $0)
    }
  }

  public func importDeliciousLibrary(from url: URL) async {
    await coordinateImport(fallbackDisplayName: DeliciousLibraryImporter().descriptor.displayName) {
      try await self.importDeliciousLibrary(from: url, reporting: $0)
    }
  }

  public func importKindleLibrary(from url: URL) async {
    await coordinateImport(fallbackDisplayName: KindleLibraryImporter().descriptor.displayName) {
      try await self.importKindleLibrary(from: url, reporting: $0)
    }
  }

  public func applyPendingImport() async {
    await applyPendingImport(choices: state.importChoices)
  }

  public func cancelPendingImport() {
    guard state.pendingImportPlan != nil else { return }
    state.pendingImportPlan = nil
    state.importChoices = [:]
    statusService.report(message: "Import cancelled")
  }
}

extension BookishImportingService {
  /// Selects Import and preserves an existing proposal until it is applied or cancelled.
  private func showImportWorkflowIfReady() -> Bool {
    navigation.select(mainSection: .importing)
    guard state.pendingImportPlan == nil, !state.isPreparingImport, !state.isApplyingImport
    else {
      statusService.report(message: "Finish or cancel the current import first")
      return false
    }
    return true
  }

  /// Collects an import proposal and presents it for review.
  private func coordinateImport(
    fallbackDisplayName: String,
    perform import: (@escaping BookishImportEventReporter) async throws -> BookishImportPlan
  ) async {
    var displayName = fallbackDisplayName
    guard showImportWorkflowIfReady() else { return }
    state.pendingImportPlan = nil
    state.importChoices = [:]
    state.lastImportResult = nil
    state.importErrorMessage = nil
    state.isPreparingImport = true
    defer { state.isPreparingImport = false }

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

      state.pendingImportPlan = plan
      state.importChoices = plan.defaultChoices
      pendingImportDisplayName = displayName
      statusService.report(
        message:
          "Review \(plan.entries.count) \(displayName) \(plan.entries.count == 1 ? "record" : "records")"
      )
    } catch is CancellationError {
      statusService.report(message: "Import cancelled")
    } catch {
      state.importErrorMessage = error.localizedDescription
      statusService.report(error: error)
    }

    statusService.clearImportProgress()
  }
}

extension BookishImportingService {
  /// Imports records from a Bookish interchange file.
  func importInterchange(
    from url: URL,
    reporting event: @escaping BookishImportEventReporter
  ) async throws -> BookishImportPlan {
    try await importFile(
      from: url,
      using: BookishInterchangeImporter(),
      reporting: event
    )
  }

  /// Imports records from a Delicious Library XML file.
  func importDeliciousLibrary(
    from url: URL,
    reporting event: @escaping BookishImportEventReporter
  ) async throws -> BookishImportPlan {
    try await importFile(
      from: url,
      using: DeliciousLibraryImporter(),
      reporting: event
    )
  }

  func importKindleLibrary(
    from url: URL,
    reporting event: @escaping BookishImportEventReporter
  ) async throws -> BookishImportPlan {
    let canAccess = url.startAccessingSecurityScopedResource()
    defer { if canAccess { url.stopAccessingSecurityScopedResource() } }
    guard storageService.isLoaded else { throw BookishStorageError.notLoaded }
    return try await importRecords(
      from: KindleLibrarySource(url: url),
      using: KindleLibraryImporter(), reporting: event)
  }

  /// Collects importer events, then reconciles against a catalogue snapshot.
  func importRecords<Importer: BookishImporter>(
    from input: Importer.Input,
    using importer: Importer,
    reporting event: @escaping @MainActor (BookishImportEvent) async throws -> Void
  ) async throws -> BookishImportPlan {
    guard storageService.isLoaded else {
      throw BookishStorageError.notLoaded
    }

    var records: [BookishRecord] = []
    var completion: BookishImportSummary?
    for try await importEvent in importer.importEvents(from: input) {
      try Task.checkCancellation()

      if case .records(let batch) = importEvent {
        records.append(contentsOf: batch)
      }

      try await event(importEvent)

      if case .finished(let summary) = importEvent {
        completion = summary
        break
      }
    }

    guard let completion else { throw BookishImportingError.missingCompletion }
    let existing = try await storageService.records(matching: RecordQuery())
    return try BookishImportReconciler().plan(
      imported: BookishImportResult(
        sourceID: completion.sourceID, root: completion.root, records: records,
        diagnostics: completion.diagnostics),
      existing: existing)
  }

  func apply(_ plan: BookishImportPlan, choices: [BookishRecordID: BookishImportChoice])
    async throws -> BookishImportResolution
  {
    let current = try await storageService.records(matching: RecordQuery())
    guard
      Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
        == Dictionary(uniqueKeysWithValues: plan.existingSnapshot.map { ($0.id, $0) })
    else { throw BookishImportingError.catalogueChanged }
    let resolved = try plan.resolve(choices: choices)
    try await storageService.upsert(records: resolved.records)
    return resolved
  }
}

extension BookishImportingService {
  /// Reads a security-scoped file before importing its data with the supplied importer.
  fileprivate func importFile<Importer: BookishImporter>(
    from url: URL,
    using importer: Importer,
    reporting event: @escaping BookishImportEventReporter
  ) async throws -> BookishImportPlan where Importer.Input == Data {
    let canAccess = url.startAccessingSecurityScopedResource()
    defer {
      if canAccess {
        url.stopAccessingSecurityScopedResource()
      }
    }

    return try await importRecords(
      from: Data(contentsOf: url),
      using: importer,
      reporting: event
    )
  }
}

extension BookishEngine: BookishImportingService.Provider {}

/// Errors reported when an importer finishes without a completion event.
enum BookishImportingError: LocalizedError {
  /// The importer stream ended before reporting a summary.
  case missingCompletion
  case catalogueChanged

  /// Describes the malformed importer stream for user-facing status reporting.
  var errorDescription: String? {
    switch self {
    case .missingCompletion:
      "The import ended before reporting completion."
    case .catalogueChanged:
      "The catalogue changed during review. Read the import again before applying it."
    }
  }
}
