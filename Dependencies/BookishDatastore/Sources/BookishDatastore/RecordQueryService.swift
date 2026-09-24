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
  private var store: Store
  private var results: [RecordQueryResult]
  private var refreshVersion = 0

  /// Creates a query service.
  public init(store: Store) {
    self.store = store
    self.results = []
  }

  /// Returns a cached observable result for a query.
  public func result(matching query: RecordQuery) async throws -> RecordQueryResult {
    for result in results {
      if await result.matches(query) {
        let version = nextRefreshVersion()
        try await refresh(result, from: store, version: version)
        return result
      }
    }

    let result = await RecordQueryResult(query: query)
    results.append(result)
    let version = nextRefreshVersion()
    try await refresh(result, from: store, version: version)
    return result
  }

  /// Refreshes all live results known to this service.
  public func refreshResults() async {
    let version = nextRefreshVersion()
    let store = self.store
    for result in results {
      do {
        try await refresh(result, from: store, version: version)
      } catch {
        await result.fail(error: error, version: version)
      }
    }
  }

  /// Retargets existing observable results when a datastore replaces its record store.
  public func replaceStore(with store: Store) async {
    self.store = store
    await refreshResults()
  }

  private func nextRefreshVersion() -> Int {
    refreshVersion += 1
    return refreshVersion
  }

  private func refresh(_ result: RecordQueryResult, from store: Store, version: Int) async throws {
    let query = await result.query
    let records = try await store.records(matching: query)
    while true {
      let snapshot = await result.snapshot()
      let unchanged = snapshot.records == records
      if await result.update(
        records: records, version: version, comparedRevision: snapshot.revision,
        unchanged: unchanged)
      {
        return
      }
    }
  }
}
