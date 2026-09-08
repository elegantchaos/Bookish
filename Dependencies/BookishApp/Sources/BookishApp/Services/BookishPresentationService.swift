// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishDatastore
import BookishRecord
import Observation

/// Manages Bookish layout selection and property-presentation resolution.
@MainActor
public protocol BookishPresentation {
  /// The explicitly selected layout, when the user has overridden the default.
  var selectedLayoutID: BookishRecordID? { get set }

  /// The identifiers of all top-level layout records.
  var layoutIDs: [BookishRecordID] { get }

  /// The identifiers of layouts compatible with the active browser index.
  var compatibleLayoutIDs: [BookishRecordID] { get }

  /// Loads layouts and reconciles selection for the supplied browser index.
  func refresh(for recordIndex: BookishRecordIndex?) async throws

  /// Clears all derived presentation state.
  func reset()

  /// Returns the selected or index-default layout.
  func selectedLayout(for recordIndex: BookishRecordIndex?) async throws -> BookishRecord?

  /// Returns the explicit, type-specific, or index-default layout for a record.
  func layout(for record: BookishRecord, recordIndex: BookishRecordIndex?) async throws
    -> BookishRecord?

  /// Returns display presentations from most specific to least specific.
  func presentations(for kind: String, layout: BookishRecord?) async throws -> [BookishRecord]

  /// Returns metadata for a record kind or the universal fallback.
  func recordKindMetadata(for kind: String) async throws -> BookishRecord?
}

/// Owns observable layout state and display configuration derived from storage records.
@MainActor
@Observable
public final class BookishPresentationService {
  /// The default layout used when neither the user nor index selects one.
  private let fallbackLayoutID = BookishRecordID("datastore-all-fields-layout")

  /// The universal presentation applied after more-specific configuration.
  private let fallbackPresentationID = BookishRecordID("presentation.type.*")

  /// The store providing presentation configuration records.
  @ObservationIgnored private let storageService: BookishStorageService

  /// The loaded layouts used for resolution and compatibility checks.
  private var layouts: [BookishRecord] = []

  /// The browser index currently used to filter compatible layouts.
  private var activeRecordIndex: BookishRecordIndex?

  /// The explicitly selected layout, when the user has overridden the default.
  public var selectedLayoutID: BookishRecordID?

  /// The identifiers of all top-level layout records.
  public private(set) var layoutIDs: [BookishRecordID] = []

  /// The identifiers of layouts compatible with the active browser index.
  public var compatibleLayoutIDs: [BookishRecordID] { compatibleLayouts.map(\.id) }

  /// Creates a presentation service backed by the supplied storage service.
  public init(storageService: BookishStorageService) {
    self.storageService = storageService
  }
}

extension BookishPresentationService: BookishPresentation {
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
    layoutIDs = layouts.filter { $0.bool(BookishRecordKey.isSection) != true }.map(\.id)
    try await reconcileSelection()
  }

  public func reset() {
    selectedLayoutID = nil
    layouts = []
    layoutIDs = []
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

    if result.contains(where: { $0.id == fallbackPresentationID }) == false,
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
