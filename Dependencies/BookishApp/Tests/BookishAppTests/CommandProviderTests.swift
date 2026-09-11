// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishDatastore
import BookishImporter
import BookishImporterSamples
import BookishRecord
import Commands
import Foundation
import Testing

@testable import BookishApp

@MainActor
struct CommandProviderTests {
  @Test
  func importCommandsUseTheVendedImportPresentation() async throws {
    let importPresentation = TestImportPresentation()
    let centre = TestCommandCentre(importPresentation: importPresentation)
    let interchangeURL = URL(filePath: "/tmp/library.bookish.json")
    let deliciousLibraryURL = URL(filePath: "/tmp/library.xml")

    try await centre.perform(ImportInterchangeCommand())
    try await centre.perform(ImportOtherDeliciousLibraryCommand())
    try await centre.perform(ImportDeliciousLibrarySampleCommand(sample: .small))
    try await centre.perform(ImportSelectedInterchangeCommand(url: interchangeURL))
    try await centre.perform(ImportSelectedDeliciousLibraryCommand(url: deliciousLibraryURL))

    #expect(importPresentation.requestedInterchangeImport)
    #expect(importPresentation.requestedDeliciousLibraryImport)
    #expect(importPresentation.importedSample == .small)
    #expect(importPresentation.importedInterchangeURL == interchangeURL)
    #expect(importPresentation.importedDeliciousLibraryURL == deliciousLibraryURL)
  }

  @Test
  func browserSettingsCommandsUseTheVendedBrowserSettingsService() async throws {
    let browserSettings = TestBrowserSettings()
    let centre = TestCommandCentre(browserSettingsService: browserSettings)

    try await centre.perform(SetDebugIndexVisibilityCommand(isVisible: true))

    #expect(browserSettings.showsDebugIndexes)
  }

  @Test
  func maintenanceCommandsUseTheVendedMaintenanceService() async throws {
    let maintenanceService = TestDatastoreMaintenanceService(hasExportableRecords: true)
    let storageService = TestStorageService()
    let centre = TestCommandCentre(
      datastoreMaintenanceService: maintenanceService,
      storageService: storageService
    )

    try await centre.perform(ExportInterchangeCommand())
    try await centre.perform(RebuildRecordStoreCommand())
    try await centre.perform(ResetDatastoreCommand())

    #expect(maintenanceService.requestedInterchangeExport)
    #expect(storageService.rebuiltRecordProjection)
    #expect(storageService.resetDatastore)
  }

  @Test
  func recordActionCommandsUseTheVendedRecordActionService() async throws {
    let recordActionService = TestRecordActionService(hasSelectedRecord: true)
    let centre = TestCommandCentre(recordActionService: recordActionService)

    try await centre.perform(MarkReadingCommand())
    try await centre.perform(MarkFinishedCommand())
    try await centre.perform(SimulateRemoteMutationCommand())

    #expect(recordActionService.markedReading)
    #expect(recordActionService.markedFinished)
    #expect(recordActionService.simulatedRemoteUpdate)
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
  func automaticRecognitionCommandsUseTheVendedRecognitionService() async throws {
    let recognitionService = TestBookRecognitionWorkflow()
    let centre = TestCommandCentre(recognitionService: recognitionService)

    try await centre.perform(SelectBookRecognitionImageCommand(imageData: Data([0xFF])))
    try await centre.perform(SelectBookRecognitionProviderCommand(provider: .fake))

    #expect(recognitionService.imageData == Data([0xFF]))
    #expect(recognitionService.provider == .fake)
    #expect(recognitionService.identificationCount == 2)
  }

  @Test
  func recordActionsApplyAndRefreshASelectedRecordStatus() async {
    let recordID = BookishRecordID("book-1")
    let storage = TestRecordActionStorage(
      record: BookishRecord(id: recordID, kind: BookishRecordKind.book)
    )
    let state = TestRecordActionState(selectedRecordID: recordID)
    let statusService = TestStatusService()
    let actions = BookishRecordActionsService(
      storage: storage,
      state: state,
      statusService: statusService
    )

    await actions.markReading()

    #expect(
      storage.localMutations == [
        .setProperty(
          recordID: recordID,
          kind: BookishRecordKind.book,
          key: BookishRecordKey.status,
          value: .string("Reading")
        )
      ]
    )
    #expect(state.refreshCount == 1)
    #expect(statusService.messages == ["Set status to Reading"])
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
  BookishImportPresentationProvider,
  BookishDatastoreMaintenanceProvider,
  BookishStorageProvider,
  BookishStatusProvider,
  BookishRecordActionsProvider,
  BookishRecognitionProvider,
  BookishNavigationProvider,
  BookishBrowserSettingsProvider
{
  let importPresentation: any BookishImportPresentation
  let datastoreMaintenanceService: any BookishDatastoreMaintenance
  let storageService: any BookishStorage
  let statusService: any BookishStatus
  let recordActionService: any BookishRecordActions
  let recognitionService: any BookishRecognitionWorkflow
  let navigationService: any BookishNavigation
  let browserSettingsService: any BookishBrowserSettings

  init(
    importPresentation: any BookishImportPresentation = TestImportPresentation(),
    datastoreMaintenanceService: any BookishDatastoreMaintenance =
      TestDatastoreMaintenanceService(),
    storageService: any BookishStorage = TestStorageService(),
    statusService: any BookishStatus = TestStatusService(),
    recordActionService: any BookishRecordActions = TestRecordActionService(),
    recognitionService: any BookishRecognitionWorkflow = TestBookRecognitionWorkflow(),
    navigationService: any BookishNavigation = TestNavigationService(),
    browserSettingsService: any BookishBrowserSettings = TestBrowserSettings()
  ) {
    self.importPresentation = importPresentation
    self.datastoreMaintenanceService = datastoreMaintenanceService
    self.storageService = storageService
    self.statusService = statusService
    self.recordActionService = recordActionService
    self.recognitionService = recognitionService
    self.navigationService = navigationService
    self.browserSettingsService = browserSettingsService
  }
}

@MainActor
private final class TestBookRecognitionWorkflow: BookishRecognitionWorkflow {
  var provider: BookRecognitionProvider = .openAI
  private(set) var imageData: Data?
  let candidates: [BookRecognitionCandidate]
  var selectedCandidateIDs: Set<String>
  let isRecognizing = false
  let canAddBooks = true
  private(set) var identificationCount = 0
  private(set) var addedSelectedBooks = false

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

  func select(provider: BookRecognitionProvider) async {
    self.provider = provider
    if imageData != nil {
      await identifyBooks()
    }
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
private final class TestImportPresentation: BookishImportPresentation {
  private(set) var requestedInterchangeImport = false
  private(set) var requestedDeliciousLibraryImport = false
  private(set) var importedSample: DeliciousLibrarySample?
  private(set) var importedInterchangeURL: URL?
  private(set) var importedDeliciousLibraryURL: URL?

  func requestInterchangeImport() {
    requestedInterchangeImport = true
  }

  func requestDeliciousLibraryImport() {
    requestedDeliciousLibraryImport = true
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
}

@MainActor
private final class TestBrowserSettings: BookishBrowserSettings {
  private(set) var showsDebugIndexes = false

  func setShowsDebugIndexes(_ isVisible: Bool) async {
    showsDebugIndexes = isVisible
  }
}

@MainActor
private final class TestDatastoreMaintenanceService: BookishDatastoreMaintenance {
  let hasExportableRecords: Bool
  private(set) var requestedInterchangeExport = false
  private(set) var rebuiltRecordProjection = false
  private(set) var resetDatastore = false

  init(hasExportableRecords: Bool = false) {
    self.hasExportableRecords = hasExportableRecords
  }

  func requestInterchangeExport() async {
    requestedInterchangeExport = true
  }

  func localDatastoreDirectory() throws -> URL {
    URL.temporaryDirectory
  }

  func rebuildRecordProjection() async {
    rebuiltRecordProjection = true
  }

  func reset() async {
    resetDatastore = true
  }
}

@MainActor
private final class TestStorageService: BookishStorage {
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
private final class TestStatusService: BookishStatus {
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
private final class TestRecordActionService: BookishRecordActions {
  let hasSelectedRecord: Bool
  private(set) var markedReading = false
  private(set) var markedFinished = false
  private(set) var simulatedRemoteUpdate = false

  init(hasSelectedRecord: Bool = false) {
    self.hasSelectedRecord = hasSelectedRecord
  }

  func markReading() async {
    markedReading = true
  }

  func markFinished() async {
    markedFinished = true
  }

  func simulateRemoteUpdate() async {
    simulatedRemoteUpdate = true
  }
}

@MainActor
private final class TestNavigationService: BookishNavigation {
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

@MainActor
private final class TestRecordActionStorage: BookishRecordActionStorage {
  let isLoaded = true
  private let storedRecord: BookishRecord?
  private(set) var localMutations: [MutationOperation] = []
  private(set) var remoteMutations: [MutationRecord] = []

  init(record: BookishRecord?) {
    storedRecord = record
  }

  func record(id: BookishRecordID) async throws -> BookishRecord? {
    storedRecord?.id == id ? storedRecord : nil
  }

  func perform(_ mutation: MutationRecord) async throws {
    localMutations.append(mutation.operation)
  }

  func receiveRemoteMutation(_ mutation: MutationRecord) async throws {
    remoteMutations.append(mutation)
  }
}

@MainActor
private final class TestRecordActionState: BookishRecordActionState {
  let selectedRecordID: BookishRecordID?
  private(set) var refreshCount = 0

  init(selectedRecordID: BookishRecordID?) {
    self.selectedRecordID = selectedRecordID
  }

  func refreshRecordActionState() async throws {
    refreshCount += 1
  }
}
