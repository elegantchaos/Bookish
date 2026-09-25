// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishDatastore
import BookishImporter
import BookishImporterSamples
import BookishLookup
import BookishRecognition
import BookishRecord
import Commands
import Foundation
import Testing

@testable import BookishApp

@MainActor
struct CommandProviderTests {
  @Test
  func importCommandsUseTheVendedImportPresentation() async throws {
    let importingService = TestImportPresentation()
    let centre = TestCommandCentre(importingService: importingService)
    let interchangeURL = URL(filePath: "/tmp/library.bookish.json")
    let deliciousLibraryURL = URL(filePath: "/tmp/library.xml")

    try await centre.perform(ImportInterchangeCommand())
    try await centre.perform(ImportOtherDeliciousLibraryCommand())
    try await centre.perform(ImportKindleLibraryCommand())
    try await centre.perform(ImportDeliciousLibrarySampleCommand(sample: .small))
    try await centre.perform(ImportSelectedInterchangeCommand(url: interchangeURL))
    try await centre.perform(ImportSelectedDeliciousLibraryCommand(url: deliciousLibraryURL))
    try await centre.perform(ApplyPendingImportCommand())
    try await centre.perform(CancelPendingImportCommand())

    #expect(importingService.requestedInterchangeImport)
    #expect(importingService.requestedDeliciousLibraryImport)
    #expect(importingService.requestedKindleLibraryImport)
    #expect(importingService.importedSample == .small)
    #expect(importingService.importedInterchangeURL == interchangeURL)
    #expect(importingService.importedDeliciousLibraryURL == deliciousLibraryURL)
    #expect(importingService.appliedPendingImport)
    #expect(importingService.cancelledPendingImport)
  }

  @Test
  func browserSettingsCommandsUseTheVendedBrowserSettingsService() async throws {
    let browserSettings = TestBrowserSettings()
    let centre = TestCommandCentre(browserService: browserSettings)

    try await centre.perform(SetDebugIndexVisibilityCommand(isVisible: true))

    #expect(browserSettings.showsDebugIndexes)
  }

  @Test
  func settingsCommandsUseTheVendedPresentation() async throws {
    let settings = TestSettingsPresentation()
    let centre = TestCommandCentre(settingsPresentationService: settings)

    try await centre.perform(OpenSettingsCommand())
    #expect(settings.isOpen)
    try await centre.perform(CloseSettingsCommand())
    #expect(!settings.isOpen)
  }

  @Test
  func newCommandsUseTheVendedRecordCreation() async throws {
    let creation = TestRecordCreation()
    let centre = TestCommandCentre(recordCreationService: creation)

    try await centre.perform(NewRecordCommand(type: .book))

    #expect(creation.createdTypes == [.book])
  }

  @Test
  func maintenanceCommandsUseTheVendedMaintenanceService() async throws {
    let exporting = TestExportingService(hasExportableRecords: true)
    let storageService = TestStorageService()
    let centre = TestCommandCentre(
      exportingService: exporting,
      storageService: storageService
    )

    try await centre.perform(ExportInterchangeCommand())
    try await centre.perform(RebuildRecordStoreCommand())
    try await centre.perform(ResetDatastoreCommand())

    #expect(exporting.requestedInterchangeExport)
    #expect(storageService.rebuiltRecordProjection)
    #expect(storageService.resetDatastore)
  }

  @Test
  func recordActionCommandsUseTheVendedRecordActionService() async throws {
    let recordActionsService = TestRecordActionService(hasSelectedRecord: true)
    let centre = TestCommandCentre(recordActionsService: recordActionsService)

    try await centre.perform(MarkReadingCommand())
    try await centre.perform(MarkFinishedCommand())
    try await centre.perform(SimulateRemoteMutationCommand())

    #expect(recordActionsService.markedReading)
    #expect(recordActionsService.markedFinished)
    #expect(recordActionsService.simulatedRemoteUpdate)
  }

  @Test
  func recordActionCommandsPassTheVisibleRecordID() async throws {
    let actions = TestRecordActionService(hasSelectedRecord: true)
    let centre = TestCommandCentre(recordActionsService: actions)
    let visibleID = BookishRecordID("linked-book")

    try await centre.perform(MarkReadingCommand(recordID: visibleID))
    try await centre.perform(MarkFinishedCommand(recordID: visibleID))

    #expect(actions.lastRecordID == visibleID)
  }

  @Test
  func recognitionCommandsUseTheVendedRecognitionService() async throws {
    let recognitionService = TestBookRecognitionWorkflow(
      candidates: [
        BookRecognitionCandidate(
          title: "Refactoring", authors: ["Martin Fowler"], confidence: 0.98),
        BookRecognitionCandidate(
          title: "Domain-Driven Design", authors: ["Eric Evans"], confidence: 0.95),
      ],
      selectedCandidateIDs: ["Refactoring|Martin Fowler"]
    )
    let centre = TestCommandCentre(recognitionService: recognitionService)

    let command = AddSelectedRecognizedBooksCommand<TestCommandCentre>()

    #expect(command.name(centre: centre) == "Add Selected")
    try await centre.perform(command)

    #expect(recognitionService.addedSelectedBooks)

    recognitionService.selectAllCandidates()

    #expect(command.name(centre: centre) == "Add All")
  }

  @Test
  func recognitionSelectionCommandsUseTheVendedRecognitionService() async throws {
    let candidates = [
      BookRecognitionCandidate(title: "Refactoring", authors: [], confidence: 0.98),
      BookRecognitionCandidate(title: "Domain-Driven Design", authors: [], confidence: 0.95),
    ]
    let recognitionService = TestBookRecognitionWorkflow(candidates: candidates)
    let centre = TestCommandCentre(recognitionService: recognitionService)

    try await centre.perform(SelectAllRecognizedBooksCommand())

    #expect(recognitionService.selectedCandidateIDs == Set(candidates.map(\.id)))

    try await centre.perform(DeselectAllRecognizedBooksCommand())

    #expect(recognitionService.selectedCandidateIDs.isEmpty)
  }

  @Test
  func recognitionCommandsSelectAMethodAndCaptureTheImage() async throws {
    let recognitionService = TestBookRecognitionWorkflow()
    let centre = TestCommandCentre(recognitionService: recognitionService)

    try await centre.perform(SelectBookRecognitionImageCommand(imageData: Data([0xFF])))
    try await centre.perform(SelectRecognitionProviderCommand(.ocrOnly))
    try await centre.perform(CaptureBooksCommand())

    #expect(recognitionService.imageData == Data([0xFF]))
    #expect(recognitionService.recognitionProviderID == .ocrOnly)
    #expect(recognitionService.identificationCount == 1)
  }

  @Test
  func lookupCommandsSelectTheVendedLookupProvider() async throws {
    let lookupWorkflowService = TestBookLookupWorkflow()
    let centre = TestCommandCentre(lookupWorkflowService: lookupWorkflowService)

    try await centre.perform(SelectLookupProviderCommand(.openLibrary))

    #expect(lookupWorkflowService.selectedProviderID == .openLibrary)
  }

  @Test
  func recordActionsApplyAndRefreshASelectedRecordStatus() async throws {
    let recordID = BookishRecordID("book-1")
    let storage = try await loadedStorage(with: [
      BookishRecord(id: recordID, kind: BookishRecordKind.book)
    ])
    let navigation = TestNavigationService()
    navigation.select(recordID: recordID)
    let browser = TestBrowserSettings()
    let statusService = TestStatusService()
    let actions = BookishRecordActionsService(
      storage: storage,
      navigation: navigation,
      browser: browser,
      statusService: statusService
    )

    await actions.markReading()

    #expect(try await storage.record(id: recordID)?.string(BookishRecordKey.status) == "Reading")
    #expect(browser.refreshCount == 1)
    #expect(statusService.messages == ["Set status to Reading"])
  }

  @Test
  func recordActionsTargetTheVisibleLinkedRecord() async throws {
    let selectedID = BookishRecordID("book-1")
    let visibleID = BookishRecordID("book-2")
    let storage = try await loadedStorage(with: [
      BookishRecord(id: selectedID, kind: BookishRecordKind.book),
      BookishRecord(id: visibleID, kind: BookishRecordKind.book),
    ])
    let navigation = TestNavigationService()
    navigation.select(recordID: selectedID)
    let actions = BookishRecordActionsService(
      storage: storage,
      navigation: navigation,
      browser: TestBrowserSettings(),
      statusService: TestStatusService()
    )

    await actions.markFinished(recordID: visibleID)

    #expect(try await storage.record(id: visibleID)?.string(BookishRecordKey.status) == "Finished")
    #expect(try await storage.record(id: selectedID)?.string(BookishRecordKey.status) == nil)
  }

  /// Loads storage in a temporary directory containing the supplied records.
  private func loadedStorage(with records: [BookishRecord]) async throws -> BookishStorageService {
    let directory = URL.temporaryDirectory.appending(
      path: "CommandProviderTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    let storage = BookishStorageService(directoryURL: directory)
    try await storage.load()
    try await storage.upsert(records: records)
    return storage
  }

  @Test
  func indexCommandsUseTheVendedNavigationService() async throws {
    let navigationService = TestNavigationService(canSelectAnotherRecordIndex: true)
    let centre = TestCommandCentre(navigationService: navigationService)

    try await centre.perform(SelectNextRecordIndexCommand())
    try await centre.perform(SelectPreviousRecordIndexCommand())

    #expect(navigationService.selectedNextRecordIndex)
    #expect(navigationService.selectedPreviousRecordIndex)
  }

  @Test
  func navigationCommandsUseTheVendedNavigationService() async throws {
    let navigationService = TestNavigationService(canSelectAnotherRecord: true)
    let centre = TestCommandCentre(navigationService: navigationService)
    let recordIndexID = BookishRecordID("books")
    let recordID = BookishRecordID("book-1")

    try await centre.perform(SelectNextRecordCommand())
    try await centre.perform(SelectPreviousRecordCommand())
    try await centre.perform(NavigateToRecordCommand(recordID: BookishRecordID("linked-book")))
    try await centre.perform(SelectMainSectionCommand(section: .capture))
    try await centre.perform(SelectRecordIndexCommand(recordIndexID: recordIndexID))
    try await centre.perform(SelectRecordCommand(recordID: recordID))
    try await centre.perform(SetRecordNameFilterCommand(filter: "left hand"))

    #expect(navigationService.selectedNextRecord)
    #expect(navigationService.selectedPreviousRecord)
    #expect(navigationService.pushedRecordIDs == [BookishRecordID("linked-book")])
    #expect(navigationService.selectedMainSection == .capture)
    #expect(navigationService.selectedRecordIndexID == recordIndexID)
    #expect(navigationService.selectedRecordID == recordID)
    #expect(navigationService.recordNameFilter == "left hand")
  }
}

@MainActor
private final class TestCommandCentre:
  CommandCentre,
  BookishImportingService.Provider,
  BookishExportingService.Provider,
  BookishStorageService.Provider,
  BookishStatusService.Provider,
  BookishRecordActionsService.Provider,
  BookishRecognitionService.Provider,
  BookishLookupWorkflowService.Provider,
  BookishNavigationService.Provider,
  BookishBrowserService.Provider,
  BookishSettingsPresentationService.Provider,
  BookishRecordCreationService.Provider
{
  let importingService: any BookishImportingService.API
  let exportingService: any BookishExportingService.API
  let storageService: any BookishStorageService.API
  let statusService: any BookishStatusService.API
  let recordActionsService: any BookishRecordActionsService.API
  let recognitionService: any BookishRecognitionService.API
  let lookupWorkflowService: any BookishLookupWorkflowService.API
  let navigationService: any BookishNavigationService.API
  let browserService: any BookishBrowserService.API
  let settingsPresentationService: any BookishSettingsPresentationService.API
  let recordCreationService: any BookishRecordCreationService.API

  init(
    importingService: any BookishImportingService.API = TestImportPresentation(),
    exportingService: any BookishExportingService.API =
      TestExportingService(),
    storageService: any BookishStorageService.API = TestStorageService(),
    statusService: any BookishStatusService.API = TestStatusService(),
    recordActionsService: any BookishRecordActionsService.API = TestRecordActionService(),
    recognitionService: any BookishRecognitionService.API = TestBookRecognitionWorkflow(),
    lookupWorkflowService: any BookishLookupWorkflowService.API = TestBookLookupWorkflow(),
    navigationService: any BookishNavigationService.API = TestNavigationService(),
    browserService: any BookishBrowserService.API = TestBrowserSettings(),
    settingsPresentationService: any BookishSettingsPresentationService.API =
      TestSettingsPresentation(),
    recordCreationService: any BookishRecordCreationService.API = TestRecordCreation()
  ) {
    self.importingService = importingService
    self.exportingService = exportingService
    self.storageService = storageService
    self.statusService = statusService
    self.recordActionsService = recordActionsService
    self.recognitionService = recognitionService
    self.lookupWorkflowService = lookupWorkflowService
    self.navigationService = navigationService
    self.browserService = browserService
    self.settingsPresentationService = settingsPresentationService
    self.recordCreationService = recordCreationService
  }
}

@MainActor
private final class TestBookLookupWorkflow: BookishLookupWorkflowService.API {
  private(set) var selectedProviderID: BookLookupProviderID = .fake
  let isLookingUp = false
  let canLookupBooks = true
  private(set) var didLookupBooks = false

  func lookupBooks() async {
    didLookupBooks = true
  }

  func selectProvider(_ providerID: BookLookupProviderID) {
    selectedProviderID = providerID
  }

  func isProviderSupported(_: BookLookupProviderID) -> Bool {
    true
  }
}

@MainActor
private final class TestSettingsPresentation: BookishSettingsPresentationService.API {
  private(set) var isOpen = false

  func openSettings() {
    isOpen = true
  }

  func closeSettings() {
    isOpen = false
  }
}

@MainActor
private final class TestRecordCreation: BookishRecordCreationService.API {
  private(set) var createdTypes: [BookishNewRecordType] = []

  func canCreate(_: BookishNewRecordType) -> Bool { true }

  func create(_ type: BookishNewRecordType) async throws {
    createdTypes.append(type)
  }
}

@MainActor
private final class TestBookRecognitionWorkflow: BookishRecognitionService.API {
  private(set) var recognitionProviderID: BookRecognitionProviderID = .fake
  private(set) var imageData: Data?
  let candidates: [BookRecognitionCandidate]
  var selectedCandidateIDs: Set<String>
  let isRecognizing = false
  let canAddBooks = true
  private(set) var identificationCount = 0
  private(set) var addedSelectedBooks = false

  var hasImage: Bool {
    imageData != nil
  }

  var isCurrentRecognitionProviderSupported: Bool {
    isRecognitionProviderSupported(recognitionProviderID)
  }

  var selectedRecognitionProviderID: BookRecognitionProviderID {
    recognitionProviderID
  }

  init(
    candidates: [BookRecognitionCandidate] = [],
    selectedCandidateIDs: Set<String> = []
  ) {
    self.candidates = candidates
    self.selectedCandidateIDs = selectedCandidateIDs
    imageData = nil
  }

  func selectImage(data: Data?) {
    imageData = data
  }

  func selectRecognitionProvider(_ id: BookRecognitionProviderID) {
    guard isRecognitionProviderSupported(id) else { return }
    recognitionProviderID = id
  }

  func isRecognitionProviderSupported(_: BookRecognitionProviderID) -> Bool {
    true
  }

  func selectCaptureGoodExample() {
  }

  func identifyBooks() async {
    identificationCount += 1
  }

  func addSelectedBooks() async throws {
    addedSelectedBooks = true
  }

  func selectAllCandidates() {
    selectedCandidateIDs = Set(candidates.map(\.id))
  }

  func deselectAllCandidates() {
    selectedCandidateIDs = []
  }
}

@MainActor
private final class TestImportPresentation: BookishImportingService.API {
  var canApplyPendingImport = true
  private(set) var appliedPendingImport = false
  private(set) var cancelledPendingImport = false
  private(set) var requestedInterchangeImport = false
  private(set) var requestedDeliciousLibraryImport = false
  private(set) var requestedKindleLibraryImport = false
  private(set) var importedSample: DeliciousLibrarySample?
  private(set) var importedInterchangeURL: URL?
  private(set) var importedDeliciousLibraryURL: URL?
  private(set) var importedKindleLibraryURL: URL?

  func requestInterchangeImport() {
    requestedInterchangeImport = true
  }

  func requestDeliciousLibraryImport() {
    requestedDeliciousLibraryImport = true
  }

  func requestKindleLibraryImport() {
    requestedKindleLibraryImport = true
  }

  func importDeliciousLibrary(sample: DeliciousLibrarySample) async {
    importedSample = sample
  }

  func importInterchange(from url: URL) async {
    importedInterchangeURL = url
  }

  func importDeliciousLibrary(from url: URL) async {
    importedDeliciousLibraryURL = url
  }

  func importKindleLibrary(from url: URL) async {
    importedKindleLibraryURL = url
  }

  func applyPendingImport() async {
    appliedPendingImport = true
  }

  func cancelPendingImport() {
    cancelledPendingImport = true
  }
}

@MainActor
private final class TestBrowserSettings: BookishBrowserService.API {
  private(set) var showsDebugIndexes = false

  private(set) var refreshCount = 0

  func setShowsDebugIndexes(_ isVisible: Bool) async {
    showsDebugIndexes = isVisible
  }

  func refresh() async throws {
    refreshCount += 1
  }
}

@MainActor
private final class TestExportingService: BookishExportingService.API {
  let hasExportableRecords: Bool
  private(set) var requestedInterchangeExport = false

  init(hasExportableRecords: Bool = false) {
    self.hasExportableRecords = hasExportableRecords
  }

  func requestInterchangeExport() async {
    requestedInterchangeExport = true
  }
}

@MainActor
private final class TestStorageService: BookishStorageService.API {
  private(set) var rebuiltRecordProjection = false
  private(set) var resetDatastore = false
  func localDatastoreDirectory() throws -> URL {
    URL.temporaryDirectory
  }

  func rebuildRecordProjection() async throws {
    rebuiltRecordProjection = true
  }

  func reset() async throws {
    resetDatastore = true
  }
}

@MainActor
private final class TestStatusService: BookishStatusService.API {
  private(set) var message = ""
  let importProgress: BookishImportProgress? = nil
  private(set) var messages: [String] = []
  private(set) var errors: [any Error] = []

  func report(message: String) {
    self.message = message
    messages.append(message)
  }

  func report(error: Error) {
    message = error.localizedDescription
    errors.append(error)
  }
}

@MainActor
private final class TestRecordActionService: BookishRecordActionsService.API {
  let hasSelectedRecord: Bool
  private(set) var markedReading = false
  private(set) var markedFinished = false
  private(set) var simulatedRemoteUpdate = false
  private(set) var lastRecordID: BookishRecordID?

  init(hasSelectedRecord: Bool = false) {
    self.hasSelectedRecord = hasSelectedRecord
  }

  func canAct(on recordID: BookishRecordID?) -> Bool {
    hasSelectedRecord || recordID != nil
  }

  func markReading(recordID: BookishRecordID?) async {
    lastRecordID = recordID
    markedReading = true
  }

  func markFinished(recordID: BookishRecordID?) async {
    lastRecordID = recordID
    markedFinished = true
  }

  func simulateRemoteUpdate() async {
    simulatedRemoteUpdate = true
  }
}

@MainActor
private final class TestNavigationService: BookishNavigationService.API {
  let canSelectAnotherRecordIndex: Bool
  let canSelectAnotherRecord: Bool
  let libraryIndexes: [BookishRecordIndex] = []
  let debugIndexes: [BookishRecordIndex] = []
  private(set) var selectedNextRecordIndex = false
  private(set) var selectedPreviousRecordIndex = false
  private(set) var pushedRecordIDs: [BookishRecordID] = []
  private(set) var selectedRecordID: BookishRecordID?
  private(set) var selectedRecordIndexID: BookishRecordID?
  private(set) var selectedMainSection: BookishMainSection?
  private(set) var recordNameFilter = ""
  private(set) var selectedNextRecord = false
  private(set) var selectedPreviousRecord = false
  let recordIDs: [BookishRecordID] = []

  init(canSelectAnotherRecordIndex: Bool = false, canSelectAnotherRecord: Bool = false) {
    self.canSelectAnotherRecordIndex = canSelectAnotherRecordIndex
    self.canSelectAnotherRecord = canSelectAnotherRecord
  }

  func select(recordIndexID: BookishRecordID?) async throws {
    selectedRecordIndexID = recordIndexID
  }

  func select(mainSection: BookishMainSection?) {
    selectedMainSection = mainSection
  }

  func selectNextRecordIndex() async throws {
    selectedNextRecordIndex = true
  }

  func selectPreviousRecordIndex() async throws {
    selectedPreviousRecordIndex = true
  }

  func contains(recordID _: BookishRecordID) -> Bool {
    true
  }

  func push(recordID: BookishRecordID) {
    pushedRecordIDs.append(recordID)
  }

  func select(recordID: BookishRecordID?) {
    selectedRecordID = recordID
  }

  func setRecordNameFilter(_ filter: String) async throws {
    recordNameFilter = filter
  }

  func selectNextRecord() {
    selectedNextRecord = true
  }

  func selectPreviousRecord() {
    selectedPreviousRecord = true
  }
}
