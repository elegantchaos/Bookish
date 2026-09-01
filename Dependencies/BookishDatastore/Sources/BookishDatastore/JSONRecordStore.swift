import BookishRecord
import Foundation

/// A JSON-directory backed prototype record store for easy inspection while the design evolves.
public actor JSONRecordStore: RecordStore {
  private var recordsByID: [BookishRecordID: BookishRecord]
  private let directoryURL: URL
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  /// Creates a JSON record store rooted at a directory containing one file per record.
  public init(directoryURL: URL) async throws {
    self.directoryURL = directoryURL
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
    guard recordsByID[record.id] != record else {
      return
    }

    recordsByID[record.id] = record
    try save(record)
  }

  /// Deletes a materialised record.
  public func delete(id: BookishRecordID) async throws {
    guard recordsByID.removeValue(forKey: id) != nil else {
      return
    }

    let fileURL = recordFileURL(for: id)
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return
    }
    try FileManager.default.removeItem(at: fileURL)
  }

  /// Removes every materialised record.
  public func removeAll() async throws {
    guard !recordsByID.isEmpty else {
      return
    }

    recordsByID = [:]
    guard FileManager.default.fileExists(atPath: directoryURL.path) else {
      return
    }
    try FileManager.default.removeItem(at: directoryURL)
  }

  private func load() async throws {
    guard FileManager.default.fileExists(atPath: directoryURL.path) else {
      try migrateLegacyProjectionIfNeeded()
      return
    }

    let fileURLs = try FileManager.default.contentsOfDirectory(
      at: directoryURL,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles]
    )
    let storedRecords =
      try fileURLs
      .filter { $0.pathExtension == "json" }
      .map { try decoder.decode(BookishRecord.self, from: Data(contentsOf: $0)) }
    recordsByID = Dictionary(uniqueKeysWithValues: storedRecords.map { ($0.id, $0) })
  }

  private func migrateLegacyProjectionIfNeeded() throws {
    let legacyFileURL =
      directoryURL
      .deletingLastPathComponent()
      .appending(path: "records.json")
    guard FileManager.default.fileExists(atPath: legacyFileURL.path) else {
      return
    }

    let storedRecords = try decoder.decode(
      [BookishRecord].self, from: Data(contentsOf: legacyFileURL))
    recordsByID = Dictionary(uniqueKeysWithValues: storedRecords.map { ($0.id, $0) })

    do {
      for record in storedRecords {
        try save(record)
      }
    } catch {
      try? FileManager.default.removeItem(at: directoryURL)
      recordsByID = [:]
      throw error
    }
  }

  private func save(_ record: BookishRecord) throws {
    try FileManager.default.createDirectory(
      at: directoryURL, withIntermediateDirectories: true)
    let data = try encoder.encode(record)
    try data.write(to: recordFileURL(for: record.id), options: [.atomic])
  }

  private func recordFileURL(for id: BookishRecordID) -> URL {
    let encodedID = Data(id.rawValue.utf8)
      .base64EncodedString()
      .replacing("+", with: "-")
      .replacing("/", with: "_")
      .trimmingCharacters(in: CharacterSet(charactersIn: "="))
    return directoryURL.appending(path: "record-\(encodedID).json")
  }
}
