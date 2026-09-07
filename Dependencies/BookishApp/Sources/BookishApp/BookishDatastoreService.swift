// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishDatastore
import BookishRecord
import Foundation
import Observation

/// Owns Bookish's loaded datastore and vends operations over its materialised records.
///
/// Services that need datastore behaviour depend on this service rather than retaining
/// a `BookishDatastore` directly. Its API can be narrowed further as responsibilities
/// move out of `BookishHarness`.
@MainActor
@Observable
public final class BookishDatastoreService {
  /// The loaded datastore, when Bookish has completed startup.
  @ObservationIgnored private(set) var datastore: BookishDatastore?

  /// Creates an empty datastore service ready to receive a loaded datastore.
  public init() {
  }

  /// Replaces the datastore used by Bookish services.
  func update(datastore: BookishDatastore?) {
    self.datastore = datastore
  }

  /// Returns the materialised result for a record query.
  func recordQueryResult(matching query: RecordQuery) async throws -> RecordQueryResult {
    guard let datastore else {
      throw BookishDatastoreServiceError.notLoaded
    }

    return try await datastore.recordQueryService.result(matching: query)
  }
}

/// Errors reported when a datastore operation requires an unavailable store.
enum BookishDatastoreServiceError: LocalizedError {
  /// The datastore has not completed loading.
  case notLoaded

  /// Describes the unavailable datastore for user-facing status reporting.
  var errorDescription: String? {
    "The datastore has not been loaded."
  }
}
