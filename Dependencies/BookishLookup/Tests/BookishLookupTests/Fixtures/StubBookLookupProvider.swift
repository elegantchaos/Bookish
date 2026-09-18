// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishLookup

/// Provides deterministic success and failure responses for service tests.
struct StubBookLookupProvider: BookLookupProvider {
  /// Identifies the provider in test results.
  let id: BookLookupProviderID

  /// Supplies the result returned for each query.
  let result: Result<[BookLookupCandidate], StubError>

  /// The test-only provider label.
  let label = "Stub"

  /// Explains that the provider is used only by tests.
  let description = "Provides deterministic lookup results for tests."

  /// Returns the configured result without inspecting the query.
  func lookupBooks(matching _: BookLookupQuery) async throws -> [BookLookupCandidate] {
    try result.get()
  }
}
