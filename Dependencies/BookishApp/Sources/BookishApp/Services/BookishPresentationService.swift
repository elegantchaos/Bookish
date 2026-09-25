// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishDatastore
import BookishRecord
import Observation

/// Owns observable layout state and display configuration derived from storage records.
@MainActor
public final class BookishPresentationService {
  @MainActor
  @Observable
  public final class State {
    @ObservationIgnored private unowned let service: BookishPresentationService
    public var selectedLayoutID: BookishRecordID?
    public fileprivate(set) var layoutIDs: [BookishRecordID] = []

    fileprivate init(service: BookishPresentationService) {
      self.service = service
    }

    public var compatibleLayoutIDs: [BookishRecordID] {
      service.compatibleLayouts.map(\.id)
    }

    public func selectedLayout(for recordIndex: BookishRecordIndex?) async throws -> BookishRecord?
    {
      try await service.selectedLayout(for: recordIndex)
    }

    public func layout(for record: BookishRecord, recordIndex: BookishRecordIndex?) async throws
      -> BookishRecord?
    {
      try await service.layout(for: record, recordIndex: recordIndex)
    }

    public func presentations(for kind: String, layout: BookishRecord?) async throws
      -> [BookishRecord]
    {
      try await service.presentations(for: kind, layout: layout)
    }

    public func recordKindMetadata(for kind: String) async throws -> BookishRecord? {
      try await service.recordKindMetadata(for: kind)
    }
  }

  public private(set) lazy var state = State(service: self)

  /// The default layout used when neither the user nor index selects one.
  private let fallbackLayoutID = BookishRecordID("datastore-all-fields-layout")

  /// The universal presentation applied after more-specific configuration.
  private let fallbackPresentationID = BookishRecordID("presentation.type.*")

  /// The store providing presentation configuration records.
  private let storageService: BookishStorageService

  /// The loaded layouts used for resolution and compatibility checks.
  private var layouts: [BookishRecord] = []

  /// The browser index currently used to filter compatible layouts.
  private var activeRecordIndex: BookishRecordIndex?

  /// The explicitly selected layout, when the user has overridden the default.
  public var selectedLayoutID: BookishRecordID? {
    get { state.selectedLayoutID }
    set { state.selectedLayoutID = newValue }
  }

  /// The identifiers of all top-level layout records.
  public var layoutIDs: [BookishRecordID] { state.layoutIDs }

  /// The identifiers of layouts compatible with the active browser index.
  public var compatibleLayoutIDs: [BookishRecordID] { compatibleLayouts.map(\.id) }

  /// Creates a presentation service backed by the supplied storage service.
  public init(storageService: BookishStorageService) {
    self.storageService = storageService
  }
}

extension BookishPresentationService {
  public func refresh(for recordIndex: BookishRecordIndex?) async throws {
    activeRecordIndex = recordIndex
    guard storageService.isLoaded else {
      return
    }

    layouts = try await storageService.records(
      matching: RecordQuery(
        predicate: .kind(BookishRecordKind.layout),
        sort: [.property(BookishRecordKey.name), .id]
      ))
    state.layoutIDs = layouts.filter { $0.bool(BookishRecordKey.isSection) != true }.map(\.id)
    try await reconcileSelection()
  }

  public func reset() {
    selectedLayoutID = nil
    layouts = []
    state.layoutIDs = []
    activeRecordIndex = nil
  }

  public func selectedLayout(for recordIndex: BookishRecordIndex?) async throws -> BookishRecord? {
    try await storageService.record(
      id: selectedLayoutID ?? recordIndex?.layoutID ?? fallbackLayoutID)
  }

  public func layout(for record: BookishRecord, recordIndex: BookishRecordIndex?) async throws
    -> BookishRecord?
  {
    if selectedLayoutID != nil {
      return try await selectedLayout(for: recordIndex)
    }

    if let layout = layouts.first(where: { layout in
      layout.bool(BookishRecordKey.isSection) != true
        && layout.strings(BookishRecordKey.types)?.contains(record.kind) == true
    }) {
      return layout
    }

    return try await selectedLayout(for: recordIndex)
  }

  public func recordKindMetadata(for kind: String) async throws -> BookishRecord? {
    if let metadata = try await storageService.record(
      id: BookishRecordID("metadata.type.\(kind)"))
    {
      return metadata
    }

    return try await storageService.record(id: BookishRecordID("metadata.type.*"))
  }

  public func presentations(for kind: String, layout: BookishRecord? = nil) async throws
    -> [BookishRecord]
  {
    var result: [BookishRecord] = []

    if let id = layout?.record(BookishRecordKey.presentation),
      let record = try await storageService.record(id: id)
    {
      result.append(record)
    }

    if let metadata = try await recordKindMetadata(for: kind),
      let id = metadata.record(BookishRecordKey.presentation),
      let record = try await storageService.record(id: id)
    {
      result.append(record)
    }

    if !result.contains(where: { $0.id == fallbackPresentationID }),
      let record = try await storageService.record(id: fallbackPresentationID)
    {
      result.append(record)
    }

    return result
  }
}

extension BookishPresentationService {
  /// The top-level layouts that apply to the active browser index.
  fileprivate var compatibleLayouts: [BookishRecord] {
    guard let activeRecordIndex else {
      return layouts
    }

    return layouts.filter { layout in
      layout.bool(BookishRecordKey.isSection) != true
        && layout.matchesAnyType(in: activeRecordIndex.types)
    }
  }

  /// Clears an absent or incompatible explicit layout selection.
  fileprivate func reconcileSelection() async throws {
    guard let selectedLayoutID else {
      return
    }

    guard try await storageService.record(id: selectedLayoutID) != nil,
      compatibleLayoutIDs.contains(selectedLayoutID)
    else {
      self.selectedLayoutID = nil
      return
    }
  }
}
