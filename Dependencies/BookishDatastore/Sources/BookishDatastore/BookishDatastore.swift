import Foundation

/// A concrete service bundle used by the proof-of-concept app and integration tests.
public struct BookishDatastore: Sendable {
  /// The JSON-backed record store.
  public let recordStore: JSONRecordStore

  /// The JSON-backed mutation store.
  public let mutationStore: JSONMutationStore

  /// The read service.
  public let recordService: DefaultRecordService<JSONRecordStore>

  /// The observable query service.
  public let recordQueryService: DefaultRecordQueryService<JSONRecordStore>

  /// The write/sync service.
  public let mutationService: DefaultMutationService<JSONRecordStore, JSONMutationStore>

  /// Creates a datastore datastore using dedicated record and mutation directories below a directory.
  public init(directoryURL: URL) async throws {
    self.recordStore = try await JSONRecordStore(
      directoryURL: directoryURL.appending(path: "records", directoryHint: .isDirectory))
    self.mutationStore = try await JSONMutationStore(
      directoryURL: directoryURL.appending(path: "mutations", directoryHint: .isDirectory))
    self.recordService = DefaultRecordService(store: recordStore)
    let recordQueryService = DefaultRecordQueryService(store: recordStore)
    self.recordQueryService = recordQueryService
    self.mutationService = DefaultMutationService(
      recordStore: recordStore,
      mutationStore: mutationStore,
      projectionDidChange: {
        await recordQueryService.refreshResults()
      }
    )
  }

  /// Discards the materialised record projection and recreates it from stored mutations.
  public static func rebuildRecordProjection(directoryURL: URL) async throws -> BookishDatastore {
    let recordsDirectory = directoryURL.appending(path: "records", directoryHint: .isDirectory)
    let legacyRecordsFile = directoryURL.appending(path: "records.json")

    if FileManager.default.fileExists(atPath: recordsDirectory.path) {
      try FileManager.default.removeItem(at: recordsDirectory)
    }
    if FileManager.default.fileExists(atPath: legacyRecordsFile.path) {
      try FileManager.default.removeItem(at: legacyRecordsFile)
    }

    let datastore = try await BookishDatastore(directoryURL: directoryURL)
    try await datastore.mutationService.rebuildRecordProjection()
    return datastore
  }

  /// Removes every persisted record and mutation from a datastore directory.
  public static func reset(directoryURL: URL) throws {
    guard FileManager.default.fileExists(atPath: directoryURL.path) else {
      return
    }

    try FileManager.default.removeItem(at: directoryURL)
  }
}
