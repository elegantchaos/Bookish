import Foundation

/// A JSON-file backed prototype mutation store.
public actor JSONMutationStore: MutationStore {
  private struct State: Codable, Equatable {
    var mutations: [MutationRecord]
    var applied: Set<MutationID>
  }

  private var state: State
  private let fileURL: URL
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  /// Creates a JSON mutation store rooted at a single file URL.
  public init(fileURL: URL) async throws {
    self.fileURL = fileURL
    self.encoder = JSONEncoder.bookishDatastoreEncoder()
    self.decoder = JSONDecoder.bookishDatastoreDecoder()
    self.state = State(mutations: [], applied: [])
    try await load()
  }

  /// Appends a new mutation if it has not already been stored.
  public func append(_ mutation: MutationRecord) async throws {
    guard !state.mutations.contains(where: { $0.id == mutation.id }) else {
      return
    }

    state.mutations.append(mutation)
    try save()
  }

  /// Returns all stored mutations in creation order.
  public func mutations() async throws -> [MutationRecord] {
    state.mutations.sorted { lhs, rhs in
      if lhs.createdAt == rhs.createdAt {
        lhs.id.rawValue < rhs.id.rawValue
      } else {
        lhs.createdAt < rhs.createdAt
      }
    }
  }

  /// Marks a mutation as applied to the projection.
  public func markApplied(_ id: MutationID) async throws {
    state.applied.insert(id)
    try save()
  }

  /// Returns whether a mutation has already been applied.
  public func isApplied(_ id: MutationID) async throws -> Bool {
    state.applied.contains(id)
  }

  /// Removes every stored mutation and applied marker.
  public func removeAll() async throws {
    state = State(mutations: [], applied: [])
    try save()
  }

  private func load() async throws {
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return
    }

    let data = try Data(contentsOf: fileURL)
    state = try decoder.decode(State.self, from: data)
  }

  private func save() throws {
    try FileManager.default.createDirectory(
      at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    let data = try encoder.encode(state)
    try data.write(to: fileURL, options: [.atomic])
  }
}
