import Foundation

/// A JSON-directory backed local mutation store.
public actor JSONMutationStore: MutationStore {
  private struct LegacyState: Codable, Equatable {
    var mutations: [MutationRecord]
    var applied: Set<MutationID>
  }

  private var mutationsByID: [MutationID: MutationRecord]
  private var appliedMutationIDs: Set<MutationID>
  private let directoryURL: URL
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  /// Creates a JSON mutation store rooted at directories for immutable mutations and applied markers.
  public init(directoryURL: URL) async throws {
    self.directoryURL = directoryURL
    self.encoder = JSONEncoder.bookishDatastoreEncoder()
    self.decoder = JSONDecoder.bookishDatastoreDecoder()
    self.mutationsByID = [:]
    self.appliedMutationIDs = []
    try await load()
  }

  /// Appends a new mutation if it has not already been stored.
  public func append(_ mutation: MutationRecord) async throws {
    guard mutationsByID[mutation.id] == nil else {
      return
    }

    try save(mutation)
    mutationsByID[mutation.id] = mutation
  }

  /// Returns all stored mutations in creation order.
  public func mutations() async throws -> [MutationRecord] {
    mutationsByID.values.sorted { lhs, rhs in
      if lhs.createdAt == rhs.createdAt {
        lhs.id.rawValue < rhs.id.rawValue
      } else {
        lhs.createdAt < rhs.createdAt
      }
    }
  }

  /// Marks a mutation as applied to the projection.
  public func markApplied(_ id: MutationID) async throws {
    guard appliedMutationIDs.insert(id).inserted else {
      return
    }

    do {
      try saveAppliedMarker(for: id)
    } catch {
      appliedMutationIDs.remove(id)
      throw error
    }
  }

  /// Returns whether a mutation has already been applied.
  public func isApplied(_ id: MutationID) async throws -> Bool {
    appliedMutationIDs.contains(id)
  }

  /// Removes all applied markers while retaining the stored mutation history.
  public func removeAppliedMarkers() async throws {
    appliedMutationIDs = []
    guard FileManager.default.fileExists(atPath: appliedDirectoryURL.path) else {
      return
    }

    try FileManager.default.removeItem(at: appliedDirectoryURL)
  }

  /// Removes every stored mutation and applied marker.
  public func removeAll() async throws {
    guard !mutationsByID.isEmpty || !appliedMutationIDs.isEmpty else {
      return
    }

    mutationsByID = [:]
    appliedMutationIDs = []
    guard FileManager.default.fileExists(atPath: directoryURL.path) else {
      return
    }
    try FileManager.default.removeItem(at: directoryURL)
  }

  private func load() async throws {
    guard FileManager.default.fileExists(atPath: directoryURL.path) else {
      try migrateLegacyLogIfNeeded()
      return
    }

    let storedMutations = try mutationFileURLs().map {
      try decoder.decode(MutationRecord.self, from: Data(contentsOf: $0))
    }
    mutationsByID = Dictionary(uniqueKeysWithValues: storedMutations.map { ($0.id, $0) })
    appliedMutationIDs = Set(
      storedMutations.lazy.map(\.id).filter {
        FileManager.default.fileExists(atPath: self.appliedMarkerURL(for: $0).path)
      })
  }

  private func migrateLegacyLogIfNeeded() throws {
    let legacyFileURL =
      directoryURL
      .deletingLastPathComponent()
      .appending(path: "mutations.json")
    guard FileManager.default.fileExists(atPath: legacyFileURL.path) else {
      return
    }

    let legacyState = try decoder.decode(LegacyState.self, from: Data(contentsOf: legacyFileURL))
    mutationsByID = Dictionary(uniqueKeysWithValues: legacyState.mutations.map { ($0.id, $0) })
    appliedMutationIDs = legacyState.applied

    do {
      for mutation in legacyState.mutations {
        try save(mutation)
      }
      for id in legacyState.applied {
        try saveAppliedMarker(for: id)
      }
    } catch {
      try? FileManager.default.removeItem(at: directoryURL)
      mutationsByID = [:]
      appliedMutationIDs = []
      throw error
    }
  }

  private func save(_ mutation: MutationRecord) throws {
    try FileManager.default.createDirectory(
      at: mutationsDirectoryURL, withIntermediateDirectories: true)
    let data = try encoder.encode(mutation)
    try data.write(to: mutationFileURL(for: mutation.id), options: [.atomic])
  }

  private func saveAppliedMarker(for id: MutationID) throws {
    try FileManager.default.createDirectory(
      at: appliedDirectoryURL, withIntermediateDirectories: true)
    try Data().write(to: appliedMarkerURL(for: id), options: [.atomic])
  }

  private var mutationsDirectoryURL: URL {
    directoryURL.appending(path: "records", directoryHint: .isDirectory)
  }

  private var appliedDirectoryURL: URL {
    directoryURL.appending(path: "applied", directoryHint: .isDirectory)
  }

  private func mutationFileURLs() throws -> [URL] {
    guard FileManager.default.fileExists(atPath: mutationsDirectoryURL.path) else {
      return []
    }

    return try FileManager.default.contentsOfDirectory(
      at: mutationsDirectoryURL,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles]
    )
    .filter { $0.pathExtension == "json" }
  }

  private func mutationFileURL(for id: MutationID) -> URL {
    mutationsDirectoryURL.appending(
      path: "mutation-\(encodedFilenameComponent(for: id.rawValue)).json")
  }

  private func appliedMarkerURL(for id: MutationID) -> URL {
    appliedDirectoryURL.appending(path: "mutation-\(encodedFilenameComponent(for: id.rawValue))")
  }

  private func encodedFilenameComponent(for value: String) -> String {
    Data(value.utf8)
      .base64EncodedString()
      .replacing("+", with: "-")
      .replacing("/", with: "_")
      .trimmingCharacters(in: CharacterSet(charactersIn: "="))
  }
}
