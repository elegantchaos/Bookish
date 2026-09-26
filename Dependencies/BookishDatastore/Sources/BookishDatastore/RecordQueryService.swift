// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord

/// Creates and refreshes observable record query results.
public protocol RecordQueryService: Sendable {
  /// Returns an observable result for a query, narrowed by an optional refinement.
  func result(
    matching query: RecordQuery, refinement: RecordPredicate?
  ) async throws -> RecordQueryResult

  /// Replaces a result's refinement in place, without querying the store again.
  func refine(_ result: RecordQueryResult, with refinement: RecordPredicate?) async throws

  /// Refreshes all results created by this service.
  func refreshResults() async
}

extension RecordQueryService {
  /// Returns an unrefined observable result for a query.
  public func result(matching query: RecordQuery) async throws -> RecordQueryResult {
    try await result(matching: query, refinement: nil)
  }
}

/// Default query service backed by a materialised record store.
///
/// The service holds its results weakly: a result stays live, and is refreshed after
/// mutations, only while a client holds it. Clients asking for the same query and
/// refinement share one result.
///
/// For each live result the service keeps the records matching its query alone, so a
/// refinement can change, for example as a user types a filter, by narrowing those
/// records rather than reading the store again.
public actor DefaultRecordQueryService<Store: RecordStore>: RecordQueryService {
  private var store: Store
  private var entries: [Entry]
  private var refreshVersion = 0

  /// Creates a query service.
  public init(store: Store) {
    self.store = store
    self.entries = []
  }

  /// The number of results still held by clients, after discarding released ones.
  var cachedResultCount: Int {
    liveEntries().count
  }

  /// Returns the live observable result for a query and refinement, creating one if no
  /// client holds it.
  public func result(
    matching query: RecordQuery, refinement: RecordPredicate?
  ) async throws -> RecordQueryResult {
    let entry: Entry
    let result: RecordQueryResult
    if let existing = liveEntries().first(where: {
      $0.query == query && $0.refinement == refinement
    }), let existingResult = existing.result {
      entry = existing
      result = existingResult
    } else {
      result = await RecordQueryResult(query: query, refinement: refinement)
      entry = Entry(query: query, refinement: refinement, result: result)
      entries.append(entry)
    }

    try await refresh(entry, holding: result, from: store, version: nextRefreshVersion())
    return result
  }

  /// Replaces a result's refinement in place, narrowing its cached query records.
  public func refine(
    _ result: RecordQueryResult, with refinement: RecordPredicate?
  ) async throws {
    guard let entry = liveEntries().first(where: { $0.result === result }) else {
      throw RecordQueryServiceError.unknownResult
    }

    entry.refinement = refinement
    await result.setRefinement(refinement)
    if let baseRecords = entry.baseRecords {
      await publish(
        baseRecords, refinedBy: entry.refinement, to: result, version: entry.baseVersion)
    } else {
      try await refresh(entry, holding: result, from: store, version: nextRefreshVersion())
    }
  }

  /// Refreshes every result still held by a client.
  public func refreshResults() async {
    let version = nextRefreshVersion()
    let store = self.store
    let live = liveEntries().compactMap { entry in entry.result.map { (entry, $0) } }
    for (entry, result) in live {
      do {
        try await refresh(entry, holding: result, from: store, version: version)
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

  /// Discards entries whose results no client holds any more, and returns the rest.
  private func liveEntries() -> [Entry] {
    entries.removeAll { $0.result == nil }
    return entries
  }

  private func nextRefreshVersion() -> Int {
    refreshVersion += 1
    return refreshVersion
  }

  /// Reads a result's query records from the store, caches them, and publishes them refined.
  private func refresh(
    _ entry: Entry, holding result: RecordQueryResult, from store: Store, version: Int
  ) async throws {
    let records = try await store.records(matching: entry.query)
    if version >= entry.baseVersion {
      entry.baseRecords = records
      entry.baseVersion = version
    }

    await publish(records, refinedBy: entry.refinement, to: result, version: version)
  }

  /// Publishes query records, narrowed by a refinement, unless a newer refresh has already.
  private func publish(
    _ records: [BookishRecord], refinedBy refinement: RecordPredicate?,
    to result: RecordQueryResult, version: Int
  ) async {
    let records = refinement.map { records.filter($0.matches) } ?? records
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

extension DefaultRecordQueryService {
  /// The service's state for one result: a weak reference to it, its query and refinement,
  /// so lookups don't hop to the main actor, and the records matching the query alone.
  private final class Entry {
    let query: RecordQuery
    var refinement: RecordPredicate?
    weak var result: RecordQueryResult?

    /// The records matching `query` before refinement, once read from the store.
    var baseRecords: [BookishRecord]?

    /// The refresh version that produced `baseRecords`.
    var baseVersion = 0

    init(query: RecordQuery, refinement: RecordPredicate?, result: RecordQueryResult) {
      self.query = query
      self.refinement = refinement
      self.result = result
    }
  }
}
