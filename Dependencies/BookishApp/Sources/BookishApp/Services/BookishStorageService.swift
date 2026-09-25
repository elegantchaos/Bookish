// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCoding
import BookishDatastore
import BookishRecord
import Commands
import Foundation
import Observation

/// Owns Bookish's loaded datastore and vends operations over its materialised records.
///
/// Services that need datastore behaviour depend on this service rather than retaining
/// a `BookishDatastore` directly.
@MainActor
public final class BookishStorageService {
  /// Performs datastore lifecycle and storage operations requested by commands.
  @MainActor
  public protocol API {
    func localDatastoreDirectory() throws -> URL
    func rebuildRecordProjection() async throws
    func reset() async throws
  }

  @MainActor
  public protocol Provider: CommandCentre {
    var storageService: any API { get }
  }

  /// Exposes the record-projection revision and read-only record queries to views.
  @MainActor
  @Observable
  public final class State {
    @ObservationIgnored private unowned let service: BookishStorageService

    /// Increments whenever views should resolve stored records again.
    ///
    /// TEMPORARY: a coarse signal that makes every visible record view reload. Remove
    /// when views observe their own records and queries; see
    /// `Extras/Journal/2026-09-25-fine-grained-record-observation.md`.
    public fileprivate(set) var revision = 0

    fileprivate init(service: BookishStorageService) {
      self.service = service
    }

    /// Returns a materialised record, if it exists.
    public func record(id: BookishRecordID) async throws -> BookishRecord? {
      try await service.record(id: id)
    }

    /// Resolves a host-specific query template against the materialised store.
    public func recordQueryResult(
      for template: RecordQueryTemplate,
      host: BookishRecord
    ) async throws -> RecordQueryResult {
      try await service.recordQueryResult(for: template, host: host)
    }

    /// Returns all durable mutations for diagnostic presentation.
    public func mutations() async throws -> [MutationRecord] {
      try await service.mutations()
    }
  }

  public private(set) lazy var state = State(service: self)

  /// The record that marks initial configuration seed import.
  private let seedMarkerID = BookishRecordID("datastore-seed-marker")

  /// An injected datastore directory for tests or a custom local store.
  private var directoryURL: URL?

  /// The loaded datastore, when Bookish has completed startup.
  private(set) var datastore: BookishDatastore?

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
    let queryService = datastore?.recordQueryService
    do {
      datastore = try await BookishDatastore(
        directoryURL: directory, recordQueryService: queryService)
    } catch {
      datastore = try await BookishDatastore.rebuildRecordProjection(
        directoryURL: directory, recordQueryService: queryService
      )
    }
    try await seed()
    if let queryService, let datastore {
      await queryService.replaceStore(with: datastore.recordStore)
    }
  }

  /// Signals views that stored records should be resolved again.
  ///
  /// TEMPORARY: remove with `State.revision`.
  func didRefreshRecords() {
    state.revision += 1
  }

  /// Applies imported records as durable local mutations.
  func upsert(records: [BookishRecord]) async throws {
    guard let datastore else { throw BookishStorageError.notLoaded }
    for record in records {
      try await datastore.mutationService.perform(.upsertRecord(record))
    }
  }

  /// Returns the materialised result for a record query.
  func recordQueryResult(matching query: RecordQuery) async throws
    -> RecordQueryResult
  {
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
    let markers = try await datastore.recordService.recordIDs(
      matching: .kind(BookishRecordKind.seedMarker)
    )
    if markers.isEmpty {
      let seed = try await importConfigurationSeeds()
      try await pruneStaleSeedConfigurationRecords(seed: seed)
      _ = try await importSeedResource("SampleSeed")
      try await writeSeedMarker()
    } else {
      _ = try await importSeedResource("MetadataSeed")
      _ = try await importSeedResource("QuerySectionSeed")
      try await addMissingSeedIndexCreationTypes()
    }
  }

  /// Adds creation metadata to existing seed indexes without replacing user changes.
  private func addMissingSeedIndexCreationTypes() async throws {
    guard let datastore,
      let url = Bundle.module.url(
        forResource: "IndexSeed.bookish", withExtension: "json")
    else { throw BookishStorageError.missingSeedResource("IndexSeed") }

    let seed = try BookishInterchangeCodec().decode(Data(contentsOf: url))
    for index in seed.records {
      guard let types = index.list(BookishRecordKey.newRecordTypes),
        let stored = try await datastore.recordStore.record(id: index.id),
        stored.list(BookishRecordKey.newRecordTypes) == nil
      else { continue }

      try await datastore.mutationService.perform(
        .setProperty(
          recordID: index.id,
          kind: BookishRecordKind.index,
          key: BookishRecordKey.newRecordTypes,
          value: .list(types)
        )
      )
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
  private func importSeedResources(_ names: [String]) async throws
    -> BookishInterchangeFile
  {
    var records: [BookishRecord] = []

    for name in names {
      let file = try await importSeedResource(name)
      records.append(contentsOf: file.records)
    }

    return BookishInterchangeFile(records: records)
  }

  /// Decodes and applies one bundled interchange resource.
  private func importSeedResource(_ name: String) async throws
    -> BookishInterchangeFile
  {
    guard let datastore else { throw BookishStorageError.notLoaded }
    guard
      let url = Bundle.module.url(
        forResource: "\(name).bookish",
        withExtension: "json"
      )
    else {
      throw BookishStorageError.missingSeedResource(name)
    }
    let file = try BookishInterchangeCodec().decode(Data(contentsOf: url))
    for record in file.records {
      try await datastore.recordStore.upsert(record)
    }
    return file
  }

  /// Removes bundled configuration records that are absent from the current seed resources.
  private func pruneStaleSeedConfigurationRecords(seed: BookishInterchangeFile)
    async throws
  {
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
      || kind == BookishRecordKind.presentation
      || kind == BookishRecordKind.metadata
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
    try await datastore.recordStore.upsert(
      BookishRecord(
        id: seedMarkerID,
        kind: BookishRecordKind.seedMarker,
        properties: [BookishRecordKey.name: .string("Seed Marker")]
      )
    )
  }
}

extension BookishStorageService: BookishStorageService.API {

  /// Rebuilds the materialised record projection and reapplies configuration seeds.
  public func rebuildRecordProjection() async throws {
    let directory = try localDatastoreDirectory()
    let queryService = datastore?.recordQueryService
    datastore = try await BookishDatastore.rebuildRecordProjection(
      directoryURL: directory,
      recordQueryService: queryService
    )
    try await seed()
    if let queryService, let datastore {
      await queryService.replaceStore(with: datastore.recordStore)
    }
  }

  /// Returns the local directory used for datastore files.
  public func localDatastoreDirectory() throws -> URL {
    if let directoryURL {
      try FileManager.default.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true
      )
      return directoryURL
    }

    let applicationSupport = try FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    let directory = applicationSupport.appending(
      path: "BookishDatastore",
      directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true
    )
    return directory
  }

  /// Resets the datastore, opens an empty replacement, and reapplies configuration seeds.
  public func reset() async throws {
    let directory = try localDatastoreDirectory()
    let queryService = datastore?.recordQueryService
    try BookishDatastore.reset(directoryURL: directory)
    datastore = try await BookishDatastore(
      directoryURL: directory, recordQueryService: queryService)
    _ = try await importConfigurationSeeds()
    try await writeSeedMarker()
    if let queryService, let datastore {
      await queryService.replaceStore(with: datastore.recordStore)
    }
  }

}

extension BookishEngine: BookishStorageService.Provider {}
