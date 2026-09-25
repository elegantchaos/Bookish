// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishDatastore
import BookishRecord
import Commands
import Foundation

/// Applies mutations to the record selected in the Bookish browser.
@MainActor
public final class BookishRecordActionsService {
  /// Performs selected-record actions requested by commands.
  @MainActor
  public protocol API: AnyObject {
    /// Whether a record is selected.
    var hasSelectedRecord: Bool { get }
    /// Whether the requested record can receive an action.
    func canAct(on recordID: BookishRecordID?) -> Bool
    /// Marks the selected record as reading.
    func markReading(recordID: BookishRecordID?) async
    /// Marks the selected record as finished.
    func markFinished(recordID: BookishRecordID?) async
    /// Simulates a remote update.
    func simulateRemoteUpdate() async
  }

  @MainActor
  public protocol Provider: CommandCentre {
    var recordActionsService: any API { get }
  }

  /// The storage service used to read and mutate records.
  private let storage: BookishStorageService

  /// The navigation service that supplies the selected record.
  private let navigation: any BookishNavigationService.API

  /// The browser service used to refresh browser content after an action.
  private let browser: any BookishBrowserService.API

  /// The status service used to report action outcomes.
  private let statusService: any BookishStatusService.API

  /// Creates record actions backed by the supplied services.
  init(
    storage: BookishStorageService,
    navigation: any BookishNavigationService.API,
    browser: any BookishBrowserService.API,
    statusService: any BookishStatusService.API
  ) {
    self.storage = storage
    self.navigation = navigation
    self.browser = browser
    self.statusService = statusService
  }
}

extension BookishRecordActionsService: BookishRecordActionsService.API {
  /// Whether an action has a selected record and loaded datastore to operate on.
  public var hasSelectedRecord: Bool {
    storage.isLoaded && navigation.selectedRecordID != nil
  }

  public func canAct(on recordID: BookishRecordID?) -> Bool {
    storage.isLoaded && (recordID ?? navigation.selectedRecordID) != nil
  }

  /// Marks the selected record as currently being read.
  public func markReading(recordID: BookishRecordID? = nil) async {
    await setStatus("Reading", recordID: recordID)
  }

  /// Marks the selected record as finished.
  public func markFinished(recordID: BookishRecordID? = nil) async {
    await setStatus("Finished", recordID: recordID)
  }

  /// Simulates a remotely-arrived mutation for the selected record.
  public func simulateRemoteUpdate() async {
    guard storage.isLoaded, let recordID = navigation.selectedRecordID else {
      return
    }

    do {
      let record = try await storage.record(id: recordID)
      let mutation = MutationRecord(
        operation: .setProperty(
          recordID: recordID,
          kind: record?.kind ?? BookishRecordKind.record,
          key: BookishRecordKey.note,
          value: .string(
            "Remote mutation arrived at \(Date().formatted(date: .omitted, time: .shortened))")
        )
      )
      try await storage.receiveRemoteMutation(mutation)
      // TEMPORARY: remove when views observe their records.
      try await browser.refresh()
      statusService.report(message: "Applied remote mutation")
    } catch {
      statusService.report(error: error)
    }
  }

  /// Updates the selected record's status property.
  private func setStatus(_ value: String, recordID requestedID: BookishRecordID?) async {
    guard storage.isLoaded, let recordID = requestedID ?? navigation.selectedRecordID else {
      return
    }

    do {
      let record = try await storage.record(id: recordID)
      try await storage.perform(
        MutationRecord(
          operation: .setProperty(
            recordID: recordID,
            kind: record?.kind ?? BookishRecordKind.record,
            key: BookishRecordKey.status,
            value: .string(value)
          )
        )
      )
      // TEMPORARY: remove when views observe their records.
      try await browser.refresh()
      statusService.report(message: "Set status to \(value)")
    } catch {
      statusService.report(error: error)
    }
  }
}

extension BookishEngine: BookishRecordActionsService.Provider {}
