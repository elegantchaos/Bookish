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

    try await centre.perform(ImportInterchangeCommand())
    try await centre.perform(ImportOtherDeliciousLibraryCommand())
    try await centre.perform(ImportDeliciousLibrarySampleCommand(sample: .small))

    #expect(importPresentation.requestedInterchangeImport)
    #expect(importPresentation.requestedDeliciousLibraryImport)
    #expect(importPresentation.importedSample == .small)
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

    try await centre.perform(SelectNextRecordCommand())
    try await centre.perform(SelectPreviousRecordCommand())
    try await centre.perform(NavigateToRecordCommand(recordID: BookishRecordID("linked-book")))

    #expect(navigationService.selectedNextRecord)
    #expect(navigationService.selectedPreviousRecord)
    #expect(navigationService.pushedRecordIDs == [BookishRecordID("linked-book")])
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
  BookishNavigationProvider
{
  let importPresentation: any BookishImportPresentation
  let datastoreMaintenanceService: any BookishDatastoreMaintenance
  let storageService: any BookishStorage
  let statusService: any BookishStatus
  let recordActionService: any BookishRecordActions
  let navigationService: any BookishNavigation

  init(
    importPresentation: any BookishImportPresentation = TestImportPresentation(),
    datastoreMaintenanceService: any BookishDatastoreMaintenance =
      TestDatastoreMaintenanceService(),
    storageService: any BookishStorage = TestStorageService(),
    statusService: any BookishStatus = TestStatusService(),
    recordActionService: any BookishRecordActions = TestRecordActionService(),
    navigationService: any BookishNavigation = TestNavigationService()
  ) {
    self.importPresentation = importPresentation
    self.datastoreMaintenanceService = datastoreMaintenanceService
    self.storageService = storageService
    self.statusService = statusService
    self.recordActionService = recordActionService
    self.navigationService = navigationService
  }
}

@MainActor
private final class TestImportPresentation: BookishImportPresentation {
  private(set) var requestedInterchangeImport = false
  private(set) var requestedDeliciousLibraryImport = false
  private(set) var importedSample: DeliciousLibrarySample?

  func requestInterchangeImport() {
    requestedInterchangeImport = true
  }

  func requestDeliciousLibraryImport() {
    requestedDeliciousLibraryImport = true
  }

  func importDeliciousLibrary(sample: DeliciousLibrarySample) async {
    importedSample = sample
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
  private(set) var selectedNextRecordIndex = false
  private(set) var selectedPreviousRecordIndex = false
  private(set) var pushedRecordIDs: [BookishRecordID] = []
  private(set) var selectedRecordID: BookishRecordID?
  private(set) var selectedNextRecord = false
  private(set) var selectedPreviousRecord = false

  init(canSelectAnotherRecordIndex: Bool = false, canSelectAnotherRecord: Bool = false) {
    self.canSelectAnotherRecordIndex = canSelectAnotherRecordIndex
    self.canSelectAnotherRecord = canSelectAnotherRecord
  }

  func select(recordIndexID _: BookishRecordID?) async throws {
  }

  func selectNextRecordIndex() async throws {
    selectedNextRecordIndex = true
  }

  func selectPreviousRecordIndex() async throws {
    selectedPreviousRecordIndex = true
  }

  func contains(recordID _: BookishRecordID) -> Bool {
    false
  }

  func push(recordID: BookishRecordID) {
    pushedRecordIDs.append(recordID)
  }

  func select(recordID: BookishRecordID?) {
    selectedRecordID = recordID
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
