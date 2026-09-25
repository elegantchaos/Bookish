// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishDatastore
import BookishRecord
import Foundation

/// Performs selected-record actions requested by commands.
@MainActor
public protocol BookishRecordActions {
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

/// The storage operations required to apply a selected-record action.
@MainActor
protocol BookishRecordActionStorage: AnyObject {
  /// Whether storage is available for record actions.
  var isLoaded: Bool { get }

  /// Resolves a record from storage.
  func record(id: BookishRecordID) async throws -> BookishRecord?

  /// Applies one durable mutation to storage.
  func perform(_ mutation: MutationRecord) async throws

  /// Applies one remotely-originated mutation to storage.
  func receiveRemoteMutation(_ mutation: MutationRecord) async throws
}

/// The UI state operations required to apply a selected-record action.
@MainActor
protocol BookishRecordActionState: AnyObject {
  /// The record selected for an action.
  var selectedRecordID: BookishRecordID? { get }

  /// Refreshes observable browser state after an action.
  func refreshRecordActionState() async throws
}

/// Applies mutations to the record selected in the Bookish browser.
@MainActor
final class BookishRecordActionsService: BookishRecordActions {
  /// The storage service used to read and mutate records.
  private unowned let storage: any BookishRecordActionStorage

  /// The UI state used to select records and refresh browser content.
  private unowned let state: any BookishRecordActionState

  /// The status service used to report action outcomes.
  private let statusService: any BookishStatusService.API

  /// Creates record actions backed by the supplied storage, UI state, and status service.
  init(
    storage: any BookishRecordActionStorage,
    state: any BookishRecordActionState,
    statusService: any BookishStatusService.API
  ) {
    self.storage = storage
    self.state = state
    self.statusService = statusService
  }

  /// Whether an action has a selected record and loaded datastore to operate on.
  var hasSelectedRecord: Bool {
    storage.isLoaded && state.selectedRecordID != nil
  }

  func canAct(on recordID: BookishRecordID?) -> Bool {
    storage.isLoaded && (recordID ?? state.selectedRecordID) != nil
  }

  /// Marks the selected record as currently being read.
  func markReading(recordID: BookishRecordID? = nil) async {
    await setStatus("Reading", recordID: recordID)
  }

  /// Marks the selected record as finished.
  func markFinished(recordID: BookishRecordID? = nil) async {
    await setStatus("Finished", recordID: recordID)
  }

  /// Simulates a remotely-arrived mutation for the selected record.
  func simulateRemoteUpdate() async {
    guard storage.isLoaded, let recordID = state.selectedRecordID else {
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
      try await state.refreshRecordActionState()
      statusService.report(message: "Applied remote mutation")
    } catch {
      statusService.report(error: error)
    }
  }

  /// Updates the selected record's status property.
  private func setStatus(_ value: String, recordID requestedID: BookishRecordID?) async {
    guard storage.isLoaded, let recordID = requestedID ?? state.selectedRecordID else {
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
      try await state.refreshRecordActionState()
      statusService.report(message: "Set status to \(value)")
    } catch {
      statusService.report(error: error)
    }
  }
}
