// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishDatastore
import BookishRecord
import Commands
import Foundation
import Observation

/// Maintains the datastore browser route independently from datastore services.
@MainActor
public final class BookishNavigationService {
  /// Performs browser index and record navigation requested by commands.
  @MainActor
  public protocol API {
    /// Whether another browser index is available.
    var canSelectAnotherRecordIndex: Bool { get }

    /// Whether another record is available in the selected browser index.
    var canSelectAnotherRecord: Bool { get }

    var selectedMainSection: BookishMainSection? { get }

    var libraryIndexes: [BookishRecordIndex] { get }

    var debugIndexes: [BookishRecordIndex] { get }

    /// Selects a browser index and refreshes its displayed records.
    func select(recordIndexID: BookishRecordID?) async throws

    /// Selects a top-level workflow and clears linked-record navigation.
    func select(mainSection: BookishMainSection?)

    /// Selects the next browser index.
    func selectNextRecordIndex() async throws

    /// Selects the previous browser index.
    func selectPreviousRecordIndex() async throws

    /// Returns whether the selected browser index contains a record.
    func contains(recordID: BookishRecordID) -> Bool

    /// Pushes a record onto the detail navigation path.
    func push(recordID: BookishRecordID)

    /// Selects a record in the selected browser index, or clears the selection.
    func select(recordID: BookishRecordID?)

    /// Updates the name filter applied to the selected browser index.
    func setRecordNameFilter(_ filter: String) async throws

    /// Selects the next record in the selected browser index.
    func selectNextRecord()

    /// Selects the previous record in the selected browser index.
    func selectPreviousRecord()

    /// The selected browser index shown in the first split-view column.
    var selectedRecordIndexID: BookishRecordID? { get }

    /// The selected record in the selected browser index.
    var selectedRecordID: BookishRecordID? { get }

    /// The records in the selected browser index.
    var recordIDs: [BookishRecordID] { get }
  }

  @MainActor
  public protocol Provider: CommandCentre {
    var navigationService: any API { get }
  }

  @MainActor
  @Observable
  public final class State {
    public fileprivate(set) var recordIndexResult: RecordQueryResult?
    public fileprivate(set) var selectedRecordIndexID: BookishRecordID?
    public fileprivate(set) var selectedMainSection: BookishMainSection?
    public fileprivate(set) var selectedRecordID: BookishRecordID?
    public fileprivate(set) var recordNavigationPath: [BookishRecordID] = []
    public fileprivate(set) var selectedRecordResult: RecordQueryResult?
    public fileprivate(set) var recordNameFilter = ""

    fileprivate init(
      selectedRecordIndexID: BookishRecordID? = nil,
      selectedMainSection: BookishMainSection? = nil
    ) {
      self.selectedRecordIndexID = selectedRecordIndexID
      self.selectedMainSection = selectedMainSection
    }

    public var recordIndexes: [BookishRecordIndex] {
      recordIndexResult?.records.map(BookishRecordIndex.init(record:)) ?? []
    }

    public var recordIndexIDs: [BookishRecordID] { recordIndexes.map(\.id) }
    public var libraryIndexes: [BookishRecordIndex] { recordIndexes.filter { !$0.isDebugOnly } }
    public var debugIndexes: [BookishRecordIndex] { recordIndexes.filter(\.isDebugOnly) }
    public var selectedRecordIndex: BookishRecordIndex? {
      recordIndexes.first { $0.id == selectedRecordIndexID }
    }
    public var selectedRecordIndexName: String? { selectedRecordIndex?.name }
    public var selectedRecordIDs: [BookishRecordID] { selectedRecordResult?.ids ?? [] }
    public var recordIDs: [BookishRecordID] { selectedRecordIDs }

    /// Applies a native detail-path binding change.
    public func setRecordNavigationPath(_ path: [BookishRecordID]) {
      recordNavigationPath = path
    }
  }

  public let state: State

  public var recordIndexResult: RecordQueryResult? {
    get { state.recordIndexResult }
    set { state.recordIndexResult = newValue }
  }
  public var selectedRecordIndexID: BookishRecordID? {
    get { state.selectedRecordIndexID }
    set { state.selectedRecordIndexID = newValue }
  }
  public var selectedMainSection: BookishMainSection? {
    get { state.selectedMainSection }
    set { state.selectedMainSection = newValue }
  }
  public var selectedRecordID: BookishRecordID? {
    get { state.selectedRecordID }
    set { state.selectedRecordID = newValue }
  }
  public var recordNavigationPath: [BookishRecordID] {
    get { state.recordNavigationPath }
    set { state.recordNavigationPath = newValue }
  }
  public var selectedRecordResult: RecordQueryResult? {
    get { state.selectedRecordResult }
    set { state.selectedRecordResult = newValue }
  }
  public var recordNameFilter: String {
    get { state.recordNameFilter }
    set { state.recordNameFilter = newValue }
  }

  /// The observable records defining the available browser indexes.
  /// The datastore service used to materialise selected browser-index queries.
  let storageService: BookishStorageService

  /// The application settings used to restore and persist the selected sidebar route.
  private let settings: UserDefaults

  /// Reconciles presentation state after a browser-index change.
  private var recordIndexSelectionHandler: (@MainActor () async throws -> Void)?

  /// Keeps an explicit Back navigation from being replaced by the first record on query refresh.
  private var isRecordSelectionCleared = false

  /// The membership callback registered on the selected query result.
  private var selectedResultObservation: (result: RecordQueryResult, token: UUID)?

  /// Creates an empty navigation service.
  public init(
    storageService: BookishStorageService = BookishStorageService(),
    settings: UserDefaults = .standard
  ) {
    self.storageService = storageService
    self.settings = settings

    switch settings.value(forKey: .lastNavigationSelection) {
    case .automatic:
      state = State()
    case .mainSection(let section):
      state = State(selectedMainSection: section)
    case .recordIndex(let recordIndexID):
      state = State(selectedRecordIndexID: recordIndexID)
    }
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

  /// The non-debug indexes presented as the user-facing library.
  public var libraryIndexes: [BookishRecordIndex] {
    recordIndexes.filter { !$0.isDebugOnly }
  }

  /// The debug and configuration indexes shown only when they are available.
  public var debugIndexes: [BookishRecordIndex] {
    recordIndexes.filter(\.isDebugOnly)
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
      setSelectedRecordResult(nil)
      selectedRecordID = nil
      recordNavigationPath = []
      isRecordSelectionCleared = false
      persistNavigationSelection()
    }
  }

  /// Updates the selected browser content result.
  public func update(selectedRecordResult: RecordQueryResult?) {
    setSelectedRecordResult(selectedRecordResult)
    selectValidRecord()
  }

  /// Replaces the observed result when the browser changes indexes or queries.
  private func setSelectedRecordResult(_ result: RecordQueryResult?) {
    if let selectedResultObservation {
      selectedResultObservation.result.removeRecordsObserver(selectedResultObservation.token)
    }
    selectedRecordResult = result
    selectedResultObservation = nil
    if let result {
      let token = result.observeRecords { [weak self] in
        self?.clearSelectionIfRecordDisappeared()
      }
      selectedResultObservation = (result, token)
    }
  }

  /// Clears detail navigation when the selected record leaves the active result.
  private func clearSelectionIfRecordDisappeared() {
    guard let selectedRecordID, !selectedRecordIDs.contains(selectedRecordID) else { return }
    self.selectedRecordID = nil
    recordNavigationPath = []
    isRecordSelectionCleared = true
  }

  /// Clears the route.
  public func reset() {
    recordIndexResult = nil
    selectedRecordIndexID = nil
    setSelectedRecordResult(nil)
    recordNameFilter = ""
    selectedRecordID = nil
    recordNavigationPath = []
    isRecordSelectionCleared = false
  }

  /// Selects a browser index, refreshes its displayed records, and reconciles presentation state.
  public func select(recordIndexID: BookishRecordID?) async throws {
    selectRecordIndex(recordIndexID: recordIndexID)
    try await refreshSelectedRecordIndex()
    try await recordIndexSelectionHandler?()
  }

  /// Selects a top-level workflow and clears linked-record navigation.
  public func select(mainSection: BookishMainSection?) {
    selectedMainSection = mainSection
    recordNavigationPath = []
    persistNavigationSelection()
  }

  /// Selects a browser index and clears stale record content.
  private func selectRecordIndex(recordIndexID: BookishRecordID?) {
    selectedMainSection = nil

    guard let recordIndexID, recordIndexIDs.contains(recordIndexID) else {
      selectedRecordIndexID = recordIndexes.first?.id
      setSelectedRecordResult(nil)
      selectedRecordID = nil
      recordNavigationPath = []
      isRecordSelectionCleared = false
      persistNavigationSelection()
      return
    }

    guard selectedRecordIndexID != recordIndexID else {
      persistNavigationSelection()
      return
    }

    selectedRecordIndexID = recordIndexID
    setSelectedRecordResult(nil)
    selectedRecordID = nil
    recordNavigationPath = []
    isRecordSelectionCleared = false
    persistNavigationSelection()
  }

  /// Selects a record identifier within the active browser index.
  public func select(recordID: BookishRecordID?) {
    recordNavigationPath = []

    guard let recordID else {
      isRecordSelectionCleared = true
      selectedRecordID = nil
      return
    }

    isRecordSelectionCleared = false
    if selectedRecordIDs.contains(recordID) {
      selectedRecordID = recordID
      return
    }

    selectedRecordID = selectedRecordIDs.first
  }

  /// Updates the name filter and refreshes the selected browser index.
  public func setRecordNameFilter(_ filter: String) async throws {
    guard recordNameFilter != filter else {
      return
    }

    recordNameFilter = filter
    try await refreshSelectedRecordIndex()
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

  /// Loads browser indexes, preserves a valid index, and refreshes its displayed records.
  public func refreshRecordIndexes(showsDebugIndexes: Bool) async throws {
    let result = try await storageService.recordQueryResult(
      matching: recordIndexQuery(showsDebugIndexes: showsDebugIndexes))
    update(recordIndexResult: result)
    try await refreshSelectedRecordIndex()
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
    if isRecordSelectionCleared {
      return
    }

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

  /// Stores the selected workflow or browser index for the next application launch.
  private func persistNavigationSelection() {
    if let selectedMainSection {
      settings.set(.mainSection(selectedMainSection), forKey: .lastNavigationSelection)
    } else if let selectedRecordIndexID {
      settings.set(.recordIndex(selectedRecordIndexID), forKey: .lastNavigationSelection)
    } else {
      settings.set(.automatic, forKey: .lastNavigationSelection)
    }
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

    let selectedRecordIndexID = selectedRecordIndex.id
    let filter = recordNameFilter
    let result = try await storageService.recordQueryResult(
      matching: query.filteringNames(containing: filter))

    guard self.selectedRecordIndexID == selectedRecordIndexID, recordNameFilter == filter else {
      return
    }

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

  /// The browser-index query for the current developer-mode visibility setting.
  private func recordIndexQuery(showsDebugIndexes: Bool) -> RecordQuery {
    let predicate: RecordPredicate
    if showsDebugIndexes {
      predicate = .kind(BookishRecordKind.index)
    } else {
      predicate = .and([
        .kind(BookishRecordKind.index),
        .not(.property(BookishRecordKey.debugOnly, equals: .bool(true))),
      ])
    }

    return RecordQuery(
      predicate: predicate,
      sort: [.property(BookishRecordKey.position), .property(BookishRecordKey.name), .id]
    )
  }

}

extension BookishNavigationService: BookishNavigationService.API {}

extension BookishEngine: BookishNavigationService.Provider {}
