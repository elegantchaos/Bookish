// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import BookishRecord
import Foundation

/// Imports normalised records into Bookish storage.
@MainActor
public protocol BookishImporting {
  /// Imports events from an importer, reporting each event after its records have been persisted.
  func importRecords<Importer: BookishImporter>(
    from input: Importer.Input,
    using importer: Importer,
    reporting event: @escaping @MainActor (BookishImportEvent) async throws -> Void
  ) async throws -> BookishImportSummary
}

/// Applies importer record batches to the storage service while preserving importer lifecycle events.
@MainActor
public final class BookishImportingService {
  /// The storage service that owns durable import mutations.
  private let storageService: BookishStorageService

  /// Creates an importer that persists records in the supplied storage service.
  public init(storageService: BookishStorageService) {
    self.storageService = storageService
  }


}

extension BookishImportingService: BookishImporting {
  /// Imports events from an importer, reporting each event after its records have been persisted.
  public func importRecords<Importer: BookishImporter>(
    from input: Importer.Input,
    using importer: Importer,
    reporting event: @escaping @MainActor (BookishImportEvent) async throws -> Void
  ) async throws -> BookishImportSummary {
    guard storageService.isLoaded else {
      throw BookishStorageError.notLoaded
    }

    for try await importEvent in importer.importEvents(from: input) {
      try Task.checkCancellation()

      if case .records(let records) = importEvent {
        try await storageService.upsert(records: records)
      }

      try await event(importEvent)

      if case .finished(let summary) = importEvent {
        return summary
      }
    }

    throw BookishImportingError.missingCompletion
  }
}

/// Errors reported when an importer finishes without a completion event.
enum BookishImportingError: LocalizedError {
  /// The importer stream ended before reporting a summary.
  case missingCompletion

  /// Describes the malformed importer stream for user-facing status reporting.
  var errorDescription: String? {
    switch self {
    case .missingCompletion:
      "The import ended before reporting completion."
    }
  }
}
