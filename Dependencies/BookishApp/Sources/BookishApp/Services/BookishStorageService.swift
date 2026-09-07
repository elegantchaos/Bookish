// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishDatastore
import BookishCoding
import BookishRecord
import Foundation
import Observation


/// Performs datastore lifecycle and storage operations requested by commands.
@MainActor
public protocol BookishStorage {
  /// Returns the datastore directory.
  func localDatastoreDirectory() throws -> URL

  /// Rebuilds the materialised record projection.
  func rebuildRecordProjection() async throws

  /// Resets the datastore and opens an empty replacement store.
  func reset() async throws
  
}


/// Owns Bookish's loaded datastore and vends operations over its materialised records.
///
/// Services that need datastore behaviour depend on this service rather than retaining
/// a `BookishDatastore` directly. Its API can be narrowed further as responsibilities
/// move out of `BookishHarness`.
@MainActor
@Observable
public final class BookishStorageService {
  /// The record that marks initial configuration seed import.
  private let seedMarkerID = BookishRecordID("datastore-seed-marker")

  /// An injected datastore directory for tests or a custom local store.
  private var directoryURL: URL?

  /// The loaded datastore, when Bookish has completed startup.
  @ObservationIgnored private(set) var datastore: BookishDatastore?

  /// Whether Bookish has loaded a datastore that can fulfil model operations.
  var isLoaded: Bool { datastore != nil }

  /// Creates an empty datastore service ready to receive a loaded datastore.
  public init(directoryURL: URL? = nil) {
    self.directoryURL = directoryURL
  }

  /// Configures the local directory before opening the datastore.
  func configure(directoryURL: URL?) {
    self.directoryURL = directoryURL
  }

  /// Opens, seeds, and retains the datastore.
  func load() async throws {
    let directory = try localDatastoreDirectory()
    do {
      datastore = try await BookishDatastore(directoryURL: directory)
    } catch {
      datastore = try await BookishDatastore.rebuildRecordProjection(directoryURL: directory)
    }
    try await seed()
  }

  /// Rebuilds the materialised record projection and reapplies configuration seeds.
  public func rebuildRecordProjection() async throws {
    let directory = try localDatastoreDirectory()
    datastore = nil
    datastore = try await BookishDatastore.rebuildRecordProjection(directoryURL: directory)
    try await seed()
  }

  /// Resets the datastore, opens an empty replacement, and reapplies configuration seeds.
  public func reset() async throws {
    let directory = try localDatastoreDirectory()
    try BookishDatastore.reset(directoryURL: directory)
    datastore = try await BookishDatastore(directoryURL: directory)
    _ = try await importConfigurationSeeds()
    try await writeSeedMarker()
  }

  /// Returns the local directory used for datastore files.
  public func localDatastoreDirectory() throws -> URL {
    if let directoryURL {
      try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
      return directoryURL
    }

    let applicationSupport = try FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    let directory = applicationSupport.appending(path: "BookishDatastore", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }

  /// Applies imported records as durable local mutations.
  func upsert(records: [BookishRecord]) async throws {
    guard let datastore else { throw BookishStorageError.notLoaded }
    for record in records {
      try await datastore.mutationService.perform(.upsertRecord(record))
    }
  }

  /// Returns the materialised result for a record query.
  func recordQueryResult(matching query: RecordQuery) async throws -> RecordQueryResult {
    guard let datastore else {
      throw BookishStorageError.notLoaded
    }

    return try await datastore.recordQueryService.result(matching: query)
  }

  /// Returns the materialised records matching a query.
  func records(matching query: RecordQuery) async throws -> [BookishRecord] {
    guard let datastore else { throw BookishStorageError.notLoaded }
    return try await datastore.recordService.records(matching: query)
  }

  /// Returns a materialised record, if it exists.
  func record(id: BookishRecordID) async throws -> BookishRecord? {
    try await datastore?.recordService.record(id: id)
  }

  /// Resolves a host-specific query template against the materialised store.
  func recordQueryResult(
    for template: RecordQueryTemplate,
    host: BookishRecord
  ) async throws -> RecordQueryResult {
    try await recordQueryResult(matching: template.resolve(for: host))
  }

  /// Returns all durable mutations for diagnostic presentation.
  func mutations() async throws -> [MutationRecord] {
    guard let datastore else { throw BookishStorageError.notLoaded }
    return try await datastore.mutationStore.mutations()
  }

  /// Applies a durable local mutation.
  func perform(_ mutation: MutationRecord) async throws {
    guard let datastore else { throw BookishStorageError.notLoaded }
    try await datastore.mutationService.perform(mutation.operation)
  }

  /// Applies a mutation received from another source.
  func receiveRemoteMutation(_ mutation: MutationRecord) async throws {
    guard let datastore else { throw BookishStorageError.notLoaded }
    try await datastore.mutationService.receiveRemoteMutation(mutation)
  }

  /// Applies configuration seeds to the loaded datastore.
  private func seed() async throws {
    guard let datastore else { throw BookishStorageError.notLoaded }
    let markers = try await datastore.recordService.recordIDs(matching: .kind(BookishRecordKind.seedMarker))
    if markers.isEmpty {
      let seed = try await importConfigurationSeeds()
      try await pruneStaleSeedConfigurationRecords(seed: seed)
      _ = try await importSeedResource("SampleSeed")
      try await writeSeedMarker()
    } else {
      _ = try await importSeedResource("MetadataSeed")
      _ = try await importSeedResource("QuerySectionSeed")
    }
  }

  /// Imports every configuration resource used by the browser and presentation layer.
  private func importConfigurationSeeds() async throws -> BookishInterchangeFile {
    try await importSeedResources([
      "IndexSeed",
      "LayoutSeed",
      "PresentationSeed",
      "MetadataSeed",
      "QuerySectionSeed",
    ])
  }

  /// Imports multiple bundled interchange resources as one aggregate interchange file.
  private func importSeedResources(_ names: [String]) async throws -> BookishInterchangeFile {
    var records: [BookishRecord] = []

    for name in names {
      let file = try await importSeedResource(name)
      records.append(contentsOf: file.records)
    }

    return BookishInterchangeFile(records: records)
  }

  /// Decodes and applies one bundled interchange resource.
  private func importSeedResource(_ name: String) async throws -> BookishInterchangeFile {
    guard let datastore else { throw BookishStorageError.notLoaded }
    guard let url = Bundle.module.url(forResource: "\(name).bookish", withExtension: "json") else {
      throw BookishStorageError.missingSeedResource(name)
    }
    let file = try BookishInterchangeCodec().decode(Data(contentsOf: url))
    for record in file.records { try await datastore.recordStore.upsert(record) }
    return file
  }

  /// Removes bundled configuration records that are absent from the current seed resources.
  private func pruneStaleSeedConfigurationRecords(seed: BookishInterchangeFile) async throws {
    guard let datastore else { throw BookishStorageError.notLoaded }
    let currentSeedConfigurationIDs = Set(
      seed.records
        .filter { isSeedConfigurationKind($0.kind) }
        .map(\.id)
    )
    let storedRecords = try await datastore.recordStore.records()

    for record in storedRecords
    where isSeedConfigurationRecord(record)
      && !currentSeedConfigurationIDs.contains(record.id)
    {
      try await datastore.recordStore.delete(id: record.id)
    }
  }

  /// Returns whether a record kind belongs to the bundled configuration projection.
  private func isSeedConfigurationKind(_ kind: String) -> Bool {
    kind == BookishRecordKind.index || kind == BookishRecordKind.layout
      || kind == BookishRecordKind.presentation || kind == BookishRecordKind.metadata
      || kind == BookishRecordKind.querySection
      || kind == "recordIndex"
  }

  /// Returns whether a record belongs to the bundled configuration projection.
  private func isSeedConfigurationRecord(_ record: BookishRecord) -> Bool {
    isSeedConfigurationKind(record.kind)
      && (record.id.rawValue.hasPrefix("datastore-")
        || record.id.rawValue.hasPrefix("presentation.type.")
        || record.id.rawValue.hasPrefix("presentation.layout.")
        || record.id.rawValue.hasPrefix("metadata.type.")
        || record.id.rawValue.hasPrefix("query-section-"))
  }

  /// Writes the marker that distinguishes initial seed import from later opens.
  private func writeSeedMarker() async throws {
    guard let datastore else { throw BookishStorageError.notLoaded }
    try await datastore.recordStore.upsert(BookishRecord(
      id: seedMarkerID,
      kind: BookishRecordKind.seedMarker,
      properties: [BookishRecordKey.name: .string("Seed Marker")]
    ))
  }
}

extension BookishStorageService: BookishStorage {
}

/// Errors reported when a datastore operation requires an unavailable store.
enum BookishStorageError: LocalizedError {
  /// The datastore has not completed loading.
  case notLoaded
  /// A bundled seed resource could not be found.
  case missingSeedResource(String)

  /// Describes the unavailable datastore for user-facing status reporting.
  var errorDescription: String? {
    switch self {
    case .notLoaded: "The datastore has not been loaded."
    case .missingSeedResource(let name): "The bundled \(name) seed resource is missing."
    }
  }
}
