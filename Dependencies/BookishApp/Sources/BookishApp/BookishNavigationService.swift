// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import Commands
import Observation

/// Maintains the datastore browser route independently from datastore services.
///
/// The service stores the active record kind and record identifier, plus the
/// lightweight index needed by navigation commands. Record contents remain in
/// the record service; mutation history is intentionally not part of this route.
@MainActor
@Observable
public final class BookishNavigationService {
  /// The available record kinds in display order.
  public private(set) var recordKinds: [String] = []

  /// The selected record kind shown in the first split-view column.
  public private(set) var selectedRecordKind: String?

  /// The selected materialised record shown in the detail column.
  public private(set) var selectedRecordID: BookishRecordID?

  private var recordIDsByKind: [String: [BookishRecordID]] = [:]

  /// Creates an empty navigation service.
  public init() {
  }

  /// All visible record identifiers across every kind.
  public var recordIDs: [BookishRecordID] {
    recordKinds.flatMap { recordIDsByKind[$0] ?? [] }
  }

  /// The record identifiers for the currently selected kind.
  public var selectedRecordIDs: [BookishRecordID] {
    guard let selectedRecordKind else {
      return []
    }

    return recordIDsByKind[selectedRecordKind] ?? []
  }

  /// Updates the navigation index from materialised records and preserves valid selection.
  public func update(records: [BookishRecord]) {
    let groupedRecords = Dictionary(grouping: records.sorted(by: sortRecords), by: \.kind)
    recordKinds = groupedRecords.keys.sorted()
    recordIDsByKind = groupedRecords.mapValues { records in records.map(\.id) }

    if let selectedRecordKind, recordKinds.contains(selectedRecordKind) {
      selectValidRecord()
    } else {
      selectedRecordKind = recordKinds.first
      selectedRecordID = selectedRecordIDs.first
    }
  }

  /// Clears the route and index.
  public func reset() {
    recordKinds = []
    recordIDsByKind = [:]
    selectedRecordKind = nil
    selectedRecordID = nil
  }

  /// Selects a record kind and defaults the record selection within it.
  public func select(kind: String?) {
    guard let kind, recordKinds.contains(kind) else {
      selectedRecordKind = recordKinds.first
      selectedRecordID = selectedRecordIDs.first
      return
    }

    selectedRecordKind = kind
    selectValidRecord()
  }

  /// Selects a record identifier within the active record kind.
  public func select(recordID: BookishRecordID?) {
    guard let recordID else {
      selectedRecordID = selectedRecordIDs.first
      return
    }

    if selectedRecordIDs.contains(recordID) {
      selectedRecordID = recordID
      return
    }

    guard let kind = recordKinds.first(where: { recordIDsByKind[$0]?.contains(recordID) == true })
    else {
      selectedRecordID = selectedRecordIDs.first
      return
    }

    selectedRecordKind = kind
    selectedRecordID = recordID
  }

  /// Returns whether a record identifier exists in the current navigation index.
  public func contains(recordID: BookishRecordID) -> Bool {
    recordIDsByKind.values.contains { $0.contains(recordID) }
  }

  /// Moves to the next available record kind.
  public func selectNextKind() {
    selectKind(offset: 1)
  }

  /// Moves to the previous available record kind.
  public func selectPreviousKind() {
    selectKind(offset: -1)
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

  private func selectKind(offset: Int) {
    guard let current = selectedRecordKind,
      let currentIndex = recordKinds.firstIndex(of: current),
      !recordKinds.isEmpty
    else {
      select(kind: recordKinds.first)
      return
    }

    let nextIndex = wrappingIndex(currentIndex + offset, count: recordKinds.count)
    select(kind: recordKinds[nextIndex])
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

  private func sortRecords(_ lhs: BookishRecord, _ rhs: BookishRecord) -> Bool {
    if lhs.kind == rhs.kind {
      lhs.id.rawValue < rhs.id.rawValue
    } else {
      lhs.kind < rhs.kind
    }
  }
}

extension BookishNavigationService: CommandCentre {
}
