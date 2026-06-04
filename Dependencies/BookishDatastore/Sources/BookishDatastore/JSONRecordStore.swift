import BookishRecord
import Foundation

/// A JSON-file backed prototype record store for easy inspection while the design evolves.
public actor JSONRecordStore: RecordStore {
  private var recordsByID: [BookishRecordID: BookishRecord]
  private let fileURL: URL
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  /// Creates a JSON record store rooted at a single file URL.
  public init(fileURL: URL) async throws {
    self.fileURL = fileURL
    self.encoder = JSONEncoder.bookishDatastoreEncoder()
    self.decoder = JSONDecoder.bookishDatastoreDecoder()
    self.recordsByID = [:]
    try await load()
  }

  /// Returns a single record by identifier.
  public func record(id: BookishRecordID) async throws -> BookishRecord? {
    recordsByID[id]
  }

  /// Returns all records in stable identifier order.
  public func records() async throws -> [BookishRecord] {
    recordsByID.values.sorted { $0.id.rawValue < $1.id.rawValue }
  }

  /// Returns identifiers for records matching a predicate in stable identifier order.
  public func recordIDs(matching predicate: RecordPredicate = .all) async throws
    -> [BookishRecordID]
  {
    recordsByID.values
      .filter { predicate.matches($0) }
      .map(\.id)
      .sorted { $0.rawValue < $1.rawValue }
  }

  /// Writes a materialised record.
  public func upsert(_ record: BookishRecord) async throws {
    recordsByID[record.id] = record
    try save()
  }

  /// Deletes a materialised record.
  public func delete(id: BookishRecordID) async throws {
    recordsByID[id] = nil
    try save()
  }

  /// Removes every materialised record.
  public func removeAll() async throws {
    recordsByID = [:]
    try save()
  }

  private func load() async throws {
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return
    }

    let data = try Data(contentsOf: fileURL)
    let storedRecords = try decoder.decode([BookishRecord].self, from: data)
    recordsByID = Dictionary(uniqueKeysWithValues: storedRecords.map { ($0.id, $0) })
  }

  private func save() throws {
    try FileManager.default.createDirectory(
      at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    let data = try encoder.encode(recordsByID.values.sorted { $0.id.rawValue < $1.id.rawValue })
    try data.write(to: fileURL, options: [.atomic])
  }
}
