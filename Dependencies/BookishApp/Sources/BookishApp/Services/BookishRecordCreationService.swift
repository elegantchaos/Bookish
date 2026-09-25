// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 25/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import Commands
import Foundation

/// Creates user records and reveals them in a suitable browser index.
@MainActor
public final class BookishRecordCreationService {
  /// The storage service that persists new records.
  private let storage: BookishStorageService

  /// The navigation service used to reveal and select new records.
  private let navigation: any BookishNavigationService.API

  /// The browser service used to refresh indexes after creation.
  private let browser: any BookishBrowserService.API

  /// Creates a record-creation service backed by the supplied services.
  init(
    storage: BookishStorageService,
    navigation: any BookishNavigationService.API,
    browser: any BookishBrowserService.API
  ) {
    self.storage = storage
    self.navigation = navigation
    self.browser = browser
  }
}

extension BookishRecordCreationService {
  /// Creates records requested by New commands.
  @MainActor
  public protocol API: AnyObject {
    /// Whether a visible index can show a new record of this type.
    func canCreate(_ type: BookishNewRecordType) -> Bool
    /// Creates and selects a record of the requested type.
    func create(_ type: BookishNewRecordType) async throws
  }

  @MainActor
  public protocol Access: CommandCentre {
    var recordCreationAPI: any API { get }
  }
}

extension BookishRecordCreationService: BookishRecordCreationService.API {
  /// Returns whether a standard library index accepts the requested type.
  public func canCreate(_ type: BookishNewRecordType) -> Bool {
    storage.isLoaded && creationIndex(for: newRecord(of: type)) != nil
  }

  /// Persists a new record, switches to its index, and selects it.
  public func create(_ type: BookishNewRecordType) async throws {
    let record = newRecord(of: type)
    guard let targetIndex = creationIndex(for: record) else {
      throw BookishRecordCreationError.noIndex(type)
    }

    try await storage.upsert(records: [record])
    try await navigation.select(recordIndexID: targetIndex.id)
    try await navigation.setRecordNameFilter("")
    // TEMPORARY: refreshes the browser so the new record appears; remove when
    // views observe their records and queries.
    try await browser.refresh()
    navigation.select(recordID: record.id)
  }
}

extension BookishRecordCreationService {
  /// Builds the initial record before checking index query compatibility.
  private func newRecord(of type: BookishNewRecordType) -> BookishRecord {
    BookishRecord(
      id: BookishRecordID(UUID().uuidString),
      kind: type.rawValue,
      properties: [BookishRecordKey.name: .string(type.initialName)]
    )
  }

  /// Finds a configured index whose query will include the new record.
  private func creationIndex(for record: BookishRecord) -> BookishRecordIndex? {
    guard let type = BookishNewRecordType(rawValue: record.kind) else { return nil }
    let indexes = navigation.libraryIndexes
    if let selectedIndex = indexes.first(where: { $0.id == navigation.selectedRecordIndexID }),
      selectedIndex.newRecordTypes.contains(type),
      selectedIndex.query?.predicate.matches(record) == true
    {
      return selectedIndex
    }
    return indexes.first {
      $0.newRecordTypes.contains(type) && $0.query?.predicate.matches(record) == true
    }
  }
}

extension BookishEngine: BookishRecordCreationService.Access {}
