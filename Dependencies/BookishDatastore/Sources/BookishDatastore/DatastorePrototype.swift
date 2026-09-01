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

  /// Creates a prototype datastore using dedicated record and mutation directories below a directory.
  public init(directoryURL: URL) async throws {
    self.recordStore = try await JSONRecordStore(
      directoryURL: directoryURL.appending(path: "records", directoryHint: .isDirectory))
    self.mutationStore = try await JSONMutationStore(
      directoryURL: directoryURL.appending(path: "mutations", directoryHint: .isDirectory))
    self.recordService = DefaultRecordService(store: recordStore)
    self.mutationService = DefaultMutationService(
      recordStore: recordStore, mutationStore: mutationStore)
  }
}
