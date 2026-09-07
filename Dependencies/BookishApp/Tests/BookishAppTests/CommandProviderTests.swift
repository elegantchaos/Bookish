// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporterSamples
import BookishDatastore
import BookishRecord
import Commands
import Foundation
import Testing

@testable import BookishApp

@MainActor
struct CommandProviderTests {
  @Test
  func importCommandsUseTheVendedImportService() async throws {
    let importService = TestImportService()
    let centre = TestCommandCentre(importService: importService)

    try await centre.perform(ImportInterchangeCommand())
    try await centre.perform(ImportOtherDeliciousLibraryCommand())
    try await centre.perform(ImportDeliciousLibrarySampleCommand(sample: .small))

    #expect(importService.requestedInterchangeImport)
    #expect(importService.requestedDeliciousLibraryImport)
    #expect(importService.importedSample == .small)
  }

  @Test
  func maintenanceCommandsUseTheVendedMaintenanceService() async throws {
    let maintenanceService = TestDatastoreMaintenanceService(hasExportableRecords: true)
    let centre = TestCommandCentre(datastoreMaintenanceService: maintenanceService)

    try await centre.perform(ExportInterchangeCommand())
    try await centre.perform(RebuildRecordStoreCommand())
    try await centre.perform(ResetDatastoreCommand())

    #expect(maintenanceService.requestedInterchangeExport)
    #expect(maintenanceService.rebuiltRecordProjection)
    #expect(maintenanceService.resetDatastore)
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
    let store = TestRecordActionStore(
      selectedRecordID: recordID,
      record: BookishRecord(id: recordID, kind: BookishRecordKind.book)
    )
    let actions = BookishRecordActions(store: store)

    await actions.markReading()

    #expect(
      store.localMutations == [
        .setProperty(
          recordID: recordID,
          kind: BookishRecordKind.book,
          key: BookishRecordKey.status,
          value: .string("Reading")
        )
      ]
    )
    #expect(store.refreshCount == 1)
    #expect(store.messages == ["Set status to Reading"])
  }

  @Test
  func browserIndexCommandsUseTheVendedIndexSelectionService() async throws {
    let selectionService = TestBrowserIndexSelectionService(canSelectAnotherRecordIndex: true)
    let centre = TestCommandCentre(browserIndexSelectionService: selectionService)

    try await centre.perform(SelectNextRecordIndexCommand())
    try await centre.perform(SelectPreviousRecordIndexCommand())

    #expect(selectionService.selectedNextRecordIndex)
    #expect(selectionService.selectedPreviousRecordIndex)
  }

  @Test
  func navigationCommandsUseTheVendedNavigationService() async throws {
    let navigationService = TestRecordNavigationService(canSelectAnotherRecord: true)
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
  BookishImportServiceProvider,
  BookishDatastoreMaintenanceServiceProvider,
  BookishRecordActionServiceProvider,
  BookishBrowserIndexSelectionServiceProvider,
  BookishNavigationServiceProvider
{
  let importService: any BookishImportService
  let datastoreMaintenanceService: any BookishDatastoreMaintenanceService
  let recordActionService: any BookishRecordActionService
  let browserIndexSelectionService: any BookishBrowserIndexSelectionService
  let navigationService: any BookishRecordNavigationService

  init(
    importService: any BookishImportService = TestImportService(),
    datastoreMaintenanceService: any BookishDatastoreMaintenanceService = TestDatastoreMaintenanceService(),
    recordActionService: any BookishRecordActionService = TestRecordActionService(),
    browserIndexSelectionService: any BookishBrowserIndexSelectionService = TestBrowserIndexSelectionService(),
    navigationService: any BookishRecordNavigationService = TestRecordNavigationService()
  ) {
    self.importService = importService
    self.datastoreMaintenanceService = datastoreMaintenanceService
    self.recordActionService = recordActionService
    self.browserIndexSelectionService = browserIndexSelectionService
    self.navigationService = navigationService
  }
}

@MainActor
private final class TestImportService: BookishImportService {
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
private final class TestDatastoreMaintenanceService: BookishDatastoreMaintenanceService {
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

  func report(message _: String) {
  }

  func rebuildRecordProjection() async {
    rebuiltRecordProjection = true
  }

  func reset() async {
    resetDatastore = true
  }
}

@MainActor
private final class TestRecordActionService: BookishRecordActionService {
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
private final class TestBrowserIndexSelectionService: BookishBrowserIndexSelectionService {
  let canSelectAnotherRecordIndex: Bool
  private(set) var selectedNextRecordIndex = false
  private(set) var selectedPreviousRecordIndex = false

  init(canSelectAnotherRecordIndex: Bool = false) {
    self.canSelectAnotherRecordIndex = canSelectAnotherRecordIndex
  }

  func selectNextRecordIndex() async {
    selectedNextRecordIndex = true
  }

  func selectPreviousRecordIndex() async {
    selectedPreviousRecordIndex = true
  }
}

@MainActor
private final class TestRecordNavigationService: BookishRecordNavigationService {
  let canSelectAnotherRecord: Bool
  private(set) var pushedRecordIDs: [BookishRecordID] = []
  private(set) var selectedRecordID: BookishRecordID?
  private(set) var selectedNextRecord = false
  private(set) var selectedPreviousRecord = false

  init(canSelectAnotherRecord: Bool = false) {
    self.canSelectAnotherRecord = canSelectAnotherRecord
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
private final class TestRecordActionStore: BookishRecordActionStore {
  let hasLoadedRecordStore = true
  let selectedRecordID: BookishRecordID?
  private let storedRecord: BookishRecord?
  private(set) var localMutations: [MutationOperation] = []
  private(set) var remoteMutations: [MutationRecord] = []
  private(set) var refreshCount = 0
  private(set) var messages: [String] = []
  private(set) var errors: [any Error] = []

  init(selectedRecordID: BookishRecordID?, record: BookishRecord?) {
    self.selectedRecordID = selectedRecordID
    storedRecord = record
  }

  func record(id: BookishRecordID) async throws -> BookishRecord? {
    storedRecord?.id == id ? storedRecord : nil
  }

  func performRecordActionMutation(_ mutation: MutationRecord) async throws {
    localMutations.append(mutation.operation)
  }

  func receiveRemoteRecordActionMutation(_ mutation: MutationRecord) async throws {
    remoteMutations.append(mutation)
  }

  func refreshRecordActionState() async throws {
    refreshCount += 1
  }

  func report(message: String) {
    messages.append(message)
  }

  func report(error: Error) {
    errors.append(error)
  }
}
