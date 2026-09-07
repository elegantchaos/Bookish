// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishDatastore
import BookishRecord
import Commands
import Observation

/// Maintains the datastore browser route independently from datastore services.
///
/// The service stores the active browser index and record identifier. The
/// browser indexes are materialised records, while the selected content is
/// backed by an observable query result supplied by the datastore.
@MainActor
@Observable
public final class BookishNavigationService {
  /// The observable records defining the available browser indexes.
  public private(set) var recordIndexResult: RecordQueryResult?

  /// The datastore service used to materialise selected browser-index queries.
  @ObservationIgnored let datastoreService: BookishDatastoreService

  /// Reconciles presentation state after a browser-index change.
  @ObservationIgnored private var recordIndexSelectionHandler: (@MainActor () async throws -> Void)?

  /// The selected browser index shown in the first split-view column.
  public private(set) var selectedRecordIndexID: BookishRecordID?

  /// The selected materialised record shown in the detail column.
  public private(set) var selectedRecordID: BookishRecordID?

  /// The linked records pushed from the selected record in the detail column.
  public private(set) var recordNavigationPath: [BookishRecordID] = []

  /// The records matching the selected browser index.
  public private(set) var selectedRecordResult: RecordQueryResult?

  /// Creates an empty navigation service.
  public init(datastoreService: BookishDatastoreService = BookishDatastoreService()) {
    self.datastoreService = datastoreService
  }

  /// The available browser index identifiers.
  public var recordIndexIDs: [BookishRecordID] {
    recordIndexes.map(\.id)
  }

  /// The available browser indexes in display order.
  public var recordIndexes: [BookishRecordIndex] {
    recordIndexResult?.records.map(BookishRecordIndex.init(record:)) ?? []
  }

  /// The selected browser index record.
  public var selectedRecordIndex: BookishRecordIndex? {
    guard let selectedRecordIndexID else {
      return nil
    }

    return recordIndexes.first { $0.id == selectedRecordIndexID }
  }

  /// The name of the selected browser index.
  public var selectedRecordIndexName: String? {
    selectedRecordIndex?.name
  }

  /// All record identifiers visible in the selected browser index.
  public var recordIDs: [BookishRecordID] {
    selectedRecordIDs
  }

  /// The record identifiers for the currently selected browser index.
  public var selectedRecordIDs: [BookishRecordID] {
    selectedRecordResult?.ids ?? []
  }

  /// Whether another record is available in the selected browser index.
  public var canSelectAnotherRecord: Bool {
    selectedRecordIDs.count > 1
  }

  /// Whether another browser index is available.
  public var canSelectAnotherRecordIndex: Bool {
    recordIndexIDs.count > 1
  }

  /// Sets the presentation reconciliation performed after an index selection.
  public func setRecordIndexSelectionHandler(
    _ handler: @escaping @MainActor () async throws -> Void
  ) {
    recordIndexSelectionHandler = handler
  }

  /// Updates the available browser index result and preserves a valid selection.
  public func update(recordIndexResult: RecordQueryResult?) {
    self.recordIndexResult = recordIndexResult
    if !isSelectedRecordIndexValid {
      selectedRecordIndexID = recordIndexes.first?.id
      selectedRecordResult = nil
      selectedRecordID = nil
      recordNavigationPath = []
    }
  }

  /// Updates the selected browser content result.
  public func update(selectedRecordResult: RecordQueryResult?) {
    self.selectedRecordResult = selectedRecordResult
    selectValidRecord()
  }

  /// Clears the route.
  public func reset() {
    recordIndexResult = nil
    selectedRecordIndexID = nil
    selectedRecordResult = nil
    selectedRecordID = nil
    recordNavigationPath = []
  }

  /// Selects a browser index, refreshes its displayed records, and reconciles presentation state.
  public func select(recordIndexID: BookishRecordID?) async throws {
    selectRecordIndex(recordIndexID: recordIndexID)
    try await refreshSelectedRecordIndex()
    try await recordIndexSelectionHandler?()
  }

  /// Selects a browser index and clears stale record content.
  private func selectRecordIndex(recordIndexID: BookishRecordID?) {
    guard let recordIndexID, recordIndexIDs.contains(recordIndexID) else {
      selectedRecordIndexID = recordIndexes.first?.id
      selectedRecordResult = nil
      selectedRecordID = nil
      recordNavigationPath = []
      return
    }

    guard selectedRecordIndexID != recordIndexID else {
      return
    }

    selectedRecordIndexID = recordIndexID
    selectedRecordResult = nil
    selectedRecordID = nil
    recordNavigationPath = []
  }

  /// Selects a record identifier within the active browser index.
  public func select(recordID: BookishRecordID?) {
    recordNavigationPath = []

    guard let recordID else {
      selectedRecordID = selectedRecordIDs.first
      return
    }

    if selectedRecordIDs.contains(recordID) {
      selectedRecordID = recordID
      return
    }

    selectedRecordID = selectedRecordIDs.first
  }

  /// Returns whether a record identifier exists in the selected browser index.
  public func contains(recordID: BookishRecordID) -> Bool {
    selectedRecordIDs.contains(recordID)
  }

  /// Appends a linked record to the detail navigation path.
  public func push(recordID: BookishRecordID) {
    recordNavigationPath.append(recordID)
  }

  /// Replaces the detail navigation path after user-driven back navigation.
  public func setRecordNavigationPath(_ path: [BookishRecordID]) {
    recordNavigationPath = path
  }

  /// Moves to the next available browser index and refreshes its displayed records.
  public func selectNextRecordIndex() async throws {
    selectRecordIndex(offset: 1)
    try await refreshSelectedRecordIndex()
    try await recordIndexSelectionHandler?()
  }

  /// Moves to the previous available browser index and refreshes its displayed records.
  public func selectPreviousRecordIndex() async throws {
    selectRecordIndex(offset: -1)
    try await refreshSelectedRecordIndex()
    try await recordIndexSelectionHandler?()
  }

  /// Moves to the next available record in the selected kind.
  public func selectNextRecord() {
    selectRecord(offset: 1)
  }

  /// Moves to the previous available record in the selected kind.
  public func selectPreviousRecord() {
    selectRecord(offset: -1)
  }

  private func selectValidRecord() {
    if let selectedRecordID, selectedRecordIDs.contains(selectedRecordID) {
      return
    }

    selectedRecordID = selectedRecordIDs.first
  }

  private var isSelectedRecordIndexValid: Bool {
    guard let selectedRecordIndexID else {
      return false
    }

    return recordIndexIDs.contains(selectedRecordIndexID)
  }

  /// Materialises the query result for the selected browser index.
  public func refreshSelectedRecordIndex() async throws {
    guard let selectedRecordIndex else {
      update(selectedRecordResult: nil)
      return
    }

    guard let query = selectedRecordIndex.query else {
      update(selectedRecordResult: nil)
      return
    }

    let result = try await datastoreService.recordQueryResult(matching: query)
    update(selectedRecordResult: result)
  }

  /// Moves the selected browser index by a wrapping offset.
  private func selectRecordIndex(offset: Int) {
    guard let current = selectedRecordIndexID,
      let currentIndex = recordIndexIDs.firstIndex(of: current),
      !recordIndexIDs.isEmpty
    else {
      selectRecordIndex(recordIndexID: recordIndexIDs.first)
      return
    }

    let nextIndex = wrappingIndex(currentIndex + offset, count: recordIndexIDs.count)
    selectRecordIndex(recordIndexID: recordIndexIDs[nextIndex])
  }

  private func selectRecord(offset: Int) {
    let ids = selectedRecordIDs
    guard let current = selectedRecordID,
      let currentIndex = ids.firstIndex(of: current),
      !ids.isEmpty
    else {
      select(recordID: ids.first)
      return
    }

    let nextIndex = wrappingIndex(currentIndex + offset, count: ids.count)
    select(recordID: ids[nextIndex])
  }

  private func wrappingIndex(_ index: Int, count: Int) -> Int {
    ((index % count) + count) % count
  }

}

extension BookishNavigationService: BookishNavigation {
}
