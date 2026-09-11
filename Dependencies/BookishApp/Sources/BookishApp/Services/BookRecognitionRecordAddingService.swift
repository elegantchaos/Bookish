// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord

/// Persists recognised candidates as new book records and refreshes the browser projection.
@MainActor
final class BookRecognitionRecordAddingService: BookRecognitionRecordAdding {
  /// The storage service used to persist new records.
  private unowned let storage: BookishStorageService

  /// The UI state refreshed after records are added.
  private unowned let state: BookishUIStateService

  /// The status service used to report successful additions.
  private let statusService: any BookishStatus

  /// Creates a record-adder with application-owned services.
  init(
    storage: BookishStorageService,
    state: BookishUIStateService,
    statusService: any BookishStatus
  ) {
    self.storage = storage
    self.state = state
    self.statusService = statusService
  }

  /// Whether the datastore has completed loading.
  var canAddBooks: Bool {
    storage.isLoaded
  }

  /// Creates and persists a book record for every supplied candidate.
  func addBooks(from candidates: [BookRecognitionCandidate]) async throws {
    guard candidates.isEmpty == false else { return }
    try await storage.upsert(records: candidates.map(\.bookRecord))
    try await state.refreshBrowser()
    statusService.report(
      message: "Added \(candidates.count) \(candidates.count == 1 ? "book" : "books")"
    )
  }
}

extension BookRecognitionCandidate {
  /// Builds the initial catalogue record for a recognised book.
  var bookRecord: BookishRecord {
    BookishRecord(
      kind: BookishRecordKind.book,
      properties: [BookishRecordKey.name: .string(title)]
    )
  }
}
