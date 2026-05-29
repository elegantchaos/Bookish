import Foundation

/// A concrete service bundle used by the proof-of-concept app and integration tests.
public struct DatastorePrototype: Sendable {
  /// The JSON-backed record store.
  public let recordStore: JSONRecordStore

  /// The JSON-backed mutation store.
  public let mutationStore: JSONMutationStore

  /// The read service.
  public let recordService: DefaultRecordService<JSONRecordStore>

  /// The write/sync service.
  public let mutationService: DefaultMutationService<JSONRecordStore, JSONMutationStore>

  /// Creates a prototype datastore using `records.json` and `mutations.json` below a directory.
  public init(directoryURL: URL) async throws {
    self.recordStore = try await JSONRecordStore(
      fileURL: directoryURL.appending(path: "records.json"))
    self.mutationStore = try await JSONMutationStore(
      fileURL: directoryURL.appending(path: "mutations.json"))
    self.recordService = DefaultRecordService(store: recordStore)
    self.mutationService = DefaultMutationService(
      recordStore: recordStore, mutationStore: mutationStore)
  }
}
