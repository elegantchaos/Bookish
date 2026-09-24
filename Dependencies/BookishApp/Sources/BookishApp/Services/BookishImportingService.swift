// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishDatastore
import BookishImporter
import BookishRecord
import Foundation

/// Receives importer lifecycle events while building a proposal.
public typealias BookishImportEventReporter = @MainActor (BookishImportEvent) async throws -> Void

/// Prepares imports and applies reviewed proposals to Bookish storage.
@MainActor
public protocol BookishImporting {
  /// Imports records from a Bookish interchange file.
  func importInterchange(
    from url: URL,
    reporting event: @escaping BookishImportEventReporter
  ) async throws -> BookishImportPlan

  /// Imports records from a Delicious Library XML file.
  func importDeliciousLibrary(
    from url: URL,
    reporting event: @escaping BookishImportEventReporter
  ) async throws -> BookishImportPlan

  /// Imports new records from a user-selected Kindle database directory.
  func importKindleLibrary(
    from url: URL,
    reporting event: @escaping BookishImportEventReporter
  ) async throws -> BookishImportPlan

  /// Reads importer events into a storage-neutral proposal.
  func importRecords<Importer: BookishImporter>(
    from input: Importer.Input,
    using importer: Importer,
    reporting event: @escaping BookishImportEventReporter
  ) async throws -> BookishImportPlan

  /// Applies an explicitly reviewed proposal if the catalogue has not changed.
  func apply(_ plan: BookishImportPlan, choices: [BookishRecordID: BookishImportChoice])
    async throws
    -> BookishImportResolution
}

/// Bridges import proposals and durable storage mutations.
@MainActor
public final class BookishImportingService {
  /// The storage service that owns durable import mutations.
  private let storageService: BookishStorageService

  /// Creates an importer backed by the supplied storage service.
  public init(storageService: BookishStorageService) {
    self.storageService = storageService
  }

}

extension BookishImportingService: BookishImporting {
  /// Imports records from a Bookish interchange file.
  public func importInterchange(
    from url: URL,
    reporting event: @escaping BookishImportEventReporter
  ) async throws -> BookishImportPlan {
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
  ) async throws -> BookishImportPlan {
    try await importFile(
      from: url,
      using: DeliciousLibraryImporter(),
      reporting: event
    )
  }

  public func importKindleLibrary(
    from url: URL,
    reporting event: @escaping BookishImportEventReporter
  ) async throws -> BookishImportPlan {
    let canAccess = url.startAccessingSecurityScopedResource()
    defer { if canAccess { url.stopAccessingSecurityScopedResource() } }
    guard storageService.isLoaded else { throw BookishStorageError.notLoaded }
    return try await importRecords(
      from: KindleLibrarySource(url: url),
      using: KindleLibraryImporter(), reporting: event)
  }

  /// Collects importer events, then reconciles against a catalogue snapshot.
  public func importRecords<Importer: BookishImporter>(
    from input: Importer.Input,
    using importer: Importer,
    reporting event: @escaping @MainActor (BookishImportEvent) async throws -> Void
  ) async throws -> BookishImportPlan {
    guard storageService.isLoaded else {
      throw BookishStorageError.notLoaded
    }

    var records: [BookishRecord] = []
    var completion: BookishImportSummary?
    for try await importEvent in importer.importEvents(from: input) {
      try Task.checkCancellation()

      if case .records(let batch) = importEvent {
        records.append(contentsOf: batch)
      }

      try await event(importEvent)

      if case .finished(let summary) = importEvent {
        completion = summary
        break
      }
    }

    guard let completion else { throw BookishImportingError.missingCompletion }
    let existing = try await storageService.records(matching: RecordQuery())
    return try BookishImportReconciler().plan(
      imported: BookishImportResult(
        sourceID: completion.sourceID, root: completion.root, records: records,
        diagnostics: completion.diagnostics),
      existing: existing)
  }

  public func apply(_ plan: BookishImportPlan, choices: [BookishRecordID: BookishImportChoice])
    async throws -> BookishImportResolution
  {
    let current = try await storageService.records(matching: RecordQuery())
    guard
      Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
        == Dictionary(uniqueKeysWithValues: plan.existingSnapshot.map { ($0.id, $0) })
    else { throw BookishImportingError.catalogueChanged }
    let resolved = try plan.resolve(choices: choices)
    try await storageService.upsert(records: resolved.records)
    return resolved
  }
}

extension BookishImportingService {
  /// Reads a security-scoped file before importing its data with the supplied importer.
  fileprivate func importFile<Importer: BookishImporter>(
    from url: URL,
    using importer: Importer,
    reporting event: @escaping BookishImportEventReporter
  ) async throws -> BookishImportPlan where Importer.Input == Data {
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
  case catalogueChanged

  /// Describes the malformed importer stream for user-facing status reporting.
  var errorDescription: String? {
    switch self {
    case .missingCompletion:
      "The import ended before reporting completion."
    case .catalogueChanged:
      "The catalogue changed during review. Read the import again before applying it."
    }
  }
}
