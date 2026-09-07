// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishDatastore
import BookishRecord
import Foundation

/// The datastore operations required to apply a selected-record action.
@MainActor
protocol BookishRecordActionStore: AnyObject {
  /// Whether a datastore is available for record actions.
  var hasLoadedRecordStore: Bool { get }

  /// The record selected for an action.
  var selectedRecordID: BookishRecordID? { get }

  /// Resolves a record from the datastore.
  func record(id: BookishRecordID) async throws -> BookishRecord?

  /// Applies one durable mutation to the datastore.
  func performRecordActionMutation(_ mutation: MutationRecord) async throws

  /// Applies one remotely-originated mutation to the datastore.
  func receiveRemoteRecordActionMutation(_ mutation: MutationRecord) async throws

  /// Refreshes observable browser state after an action.
  func refreshRecordActionState() async throws

  /// Reports a user-facing message.
  func report(message: String)

  /// Reports an action failure.
  func report(error: Error)
}

/// Applies mutations to the record selected in the Bookish browser.
@MainActor
final class BookishRecordActions: BookishRecordActionService {
  /// The harness-facing datastore operations used to execute actions.
  private unowned let store: any BookishRecordActionStore

  /// Creates record actions backed by the supplied datastore operations.
  init(store: any BookishRecordActionStore) {
    self.store = store
  }

  /// Whether an action has a selected record and loaded datastore to operate on.
  var hasSelectedRecord: Bool {
    store.hasLoadedRecordStore && store.selectedRecordID != nil
  }

  /// Marks the selected record as currently being read.
  func markReading() async {
    await setStatus("Reading")
  }

  /// Marks the selected record as finished.
  func markFinished() async {
    await setStatus("Finished")
  }

  /// Simulates a remotely-arrived mutation for the selected record.
  func simulateRemoteUpdate() async {
    guard store.hasLoadedRecordStore, let recordID = store.selectedRecordID else {
      return
    }

    do {
      let record = try await store.record(id: recordID)
      let mutation = MutationRecord(
        operation: .setProperty(
          recordID: recordID,
          kind: record?.kind ?? BookishRecordKind.record,
          key: BookishRecordKey.note,
          value: .string(
            "Remote mutation arrived at \(Date().formatted(date: .omitted, time: .shortened))")
        )
      )
      try await store.receiveRemoteRecordActionMutation(mutation)
      try await store.refreshRecordActionState()
      store.report(message: "Applied remote mutation")
    } catch {
      store.report(error: error)
    }
  }

  /// Updates the selected record's status property.
  private func setStatus(_ value: String) async {
    guard store.hasLoadedRecordStore, let recordID = store.selectedRecordID else {
      return
    }

    do {
      let record = try await store.record(id: recordID)
      try await store.performRecordActionMutation(
        MutationRecord(
          operation: .setProperty(
            recordID: recordID,
            kind: record?.kind ?? BookishRecordKind.record,
            key: BookishRecordKey.status,
            value: .string(value)
          )
        )
      )
      try await store.refreshRecordActionState()
      store.report(message: "Set status to \(value)")
    } catch {
      store.report(error: error)
    }
  }
}
