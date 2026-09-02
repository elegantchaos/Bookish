// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

/// Creates and refreshes observable record query results.
public protocol RecordQueryService: Sendable {
  /// Returns an observable result for a query.
  func result(matching query: RecordQuery) async throws -> RecordQueryResult

  /// Refreshes all results created by this service.
  func refreshResults() async
}

/// Default query service backed by a materialised record store.
public actor DefaultRecordQueryService<Store: RecordStore>: RecordQueryService {
  private let store: Store
  private var results: [RecordQueryResult]

  /// Creates a query service.
  public init(store: Store) {
    self.store = store
    self.results = []
  }

  /// Returns a cached observable result for a query.
  public func result(matching query: RecordQuery) async throws -> RecordQueryResult {
    for result in results {
      if await result.matches(query) {
        try await refresh(result)
        return result
      }
    }

    let result = await RecordQueryResult(query: query)
    results.append(result)
    try await refresh(result)
    return result
  }

  /// Refreshes all live results known to this service.
  public func refreshResults() async {
    for result in results {
      do {
        try await refresh(result)
      } catch {
        await result.fail(error: error)
      }
    }
  }

  private func refresh(_ result: RecordQueryResult) async throws {
    let query = await result.query
    let records = try await store.records(matching: query)
    await result.update(records: records)
  }
}
