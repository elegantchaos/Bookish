// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import BookishRecord
import Foundation

/// Receives importer lifecycle events after their model changes have been applied.
public typealias BookishImportEventReporter = @MainActor (BookishImportEvent) async throws -> Void

/// Imports normalised records into Bookish storage.
@MainActor
public protocol BookishImporting {
  /// Imports records from a Bookish interchange file.
  func importInterchange(
    from url: URL,
    reporting event: @escaping BookishImportEventReporter
  ) async throws -> BookishImportSummary

  /// Imports records from a Delicious Library XML file.
  func importDeliciousLibrary(
    from url: URL,
    reporting event: @escaping BookishImportEventReporter
  ) async throws -> BookishImportSummary

  /// Imports events from an importer, reporting each event after its records have been persisted.
  func importRecords<Importer: BookishImporter>(
    from input: Importer.Input,
    using importer: Importer,
    reporting event: @escaping BookishImportEventReporter
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
  /// Imports records from a Bookish interchange file.
  public func importInterchange(
    from url: URL,
    reporting event: @escaping BookishImportEventReporter
  ) async throws -> BookishImportSummary {
    try await importFile(
      from: url,
      using: BookishInterchangeImporter(),
      reporting: event
    )
  }

  /// Imports records from a Delicious Library XML file.
  public func importDeliciousLibrary(
    from url: URL,
    reporting event: @escaping BookishImportEventReporter
  ) async throws -> BookishImportSummary {
    try await importFile(
      from: url,
      using: DeliciousLibraryImporter(),
      reporting: event
    )
  }

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

private extension BookishImportingService {
  /// Reads a security-scoped file before importing its data with the supplied importer.
  func importFile<Importer: BookishImporter>(
    from url: URL,
    using importer: Importer,
    reporting event: @escaping BookishImportEventReporter
  ) async throws -> BookishImportSummary where Importer.Input == Data {
    let canAccess = url.startAccessingSecurityScopedResource()
    defer {
      if canAccess {
        url.stopAccessingSecurityScopedResource()
      }
    }

    return try await importRecords(
      from: Data(contentsOf: url),
      using: importer,
      reporting: event
    )
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
