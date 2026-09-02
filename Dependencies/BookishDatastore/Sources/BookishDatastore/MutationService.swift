import BookishRecord
import Foundation

/// Applies durable mutations to the materialised record projection.
public protocol MutationService: Sendable {
  /// Stores and applies a local mutation.
  func perform(_ operation: MutationOperation) async throws -> MutationRecord

  /// Stores and applies a remotely-arrived mutation.
  func receiveRemoteMutation(_ mutation: MutationRecord) async throws

  /// Replays unapplied stored mutations into the record store.
  func processPendingMutations() async throws
}

/// Default local mutation service.
public struct DefaultMutationService<Records: RecordStore, Mutations: MutationStore>:
  MutationService
{
  private let recordStore: Records
  private let mutationStore: Mutations
  private let projectionDidChange: (@Sendable () async -> Void)?

  /// Creates a mutation service.
  public init(
    recordStore: Records,
    mutationStore: Mutations,
    projectionDidChange: (@Sendable () async -> Void)? = nil
  ) {
    self.recordStore = recordStore
    self.mutationStore = mutationStore
    self.projectionDidChange = projectionDidChange
  }

  /// Stores and applies a local mutation.
  @discardableResult
  public func perform(_ operation: MutationOperation) async throws -> MutationRecord {
    let mutation = MutationRecord(operation: operation)
    try await receiveRemoteMutation(mutation)
    return mutation
  }

  /// Stores and applies a remotely-arrived mutation.
  public func receiveRemoteMutation(_ mutation: MutationRecord) async throws {
    try await mutationStore.append(mutation)
    let didApply = try await applyIfNeeded(mutation)
    if didApply {
      await projectionDidChange?()
    }
  }

  /// Replays unapplied stored mutations into the record store.
  public func processPendingMutations() async throws {
    var didApply = false
    for mutation in try await mutationStore.mutations() {
      didApply = try await applyIfNeeded(mutation) || didApply
    }

    if didApply {
      await projectionDidChange?()
    }
  }

  private func applyIfNeeded(_ mutation: MutationRecord) async throws -> Bool {
    guard try await !mutationStore.isApplied(mutation.id) else {
      return false
    }

    try await apply(mutation.operation)
    try await mutationStore.markApplied(mutation.id)
    return true
  }

  private func apply(_ operation: MutationOperation) async throws {
    switch operation {
    case .upsertRecord(let record):
      try await recordStore.upsert(record)

    case .setProperty(let recordID, let kind, let key, let value):
      var record =
        try await recordStore.record(id: recordID) ?? BookishRecord(id: recordID, kind: kind)
      record.properties[key] = value
      try await recordStore.upsert(record)

    case .deleteProperty(let recordID, let key):
      guard var record = try await recordStore.record(id: recordID) else {
        return
      }

      record.properties[key] = nil
      try await recordStore.upsert(record)

    case .deleteRecord(let recordID):
      try await recordStore.delete(id: recordID)
    }
  }
}
