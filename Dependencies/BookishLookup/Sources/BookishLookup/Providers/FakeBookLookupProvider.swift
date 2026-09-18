// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Returns deterministic metadata candidates for previews, demos, and tests.
public struct FakeBookLookupProvider: BookLookupProvider {
  /// The stable identifier for the fake provider.
  public let id = "fake"

  /// The user-facing provider name.
  public let label = "Fake"

  /// Explains that the provider does not contact a remote catalogue.
  public let description = "Returns a fixed sample of book metadata without a network request."

  /// Creates the fake provider.
  public init() {}

  /// Returns the same sample candidates for every query.
  public func lookupBooks(matching _: BookLookupQuery) async throws -> [BookLookupCandidate] {
    Self.sampleCandidates
  }

  /// The candidates returned by the provider.
  public static let sampleCandidates = [
    BookLookupCandidate(
      providerID: "fake",
      sourceID: "left-hand-of-darkness",
      title: "The Left Hand of Darkness",
      authors: ["Ursula K. Le Guin"],
      publisher: "Ace Books",
      publishedDate: "1969",
      isbn13: "9780441478125"
    ),
    BookLookupCandidate(
      providerID: "fake",
      sourceID: "fifth-season",
      title: "The Fifth Season",
      authors: ["N. K. Jemisin"],
      publisher: "Orbit",
      publishedDate: "2015",
      isbn13: "9780316229296"
    ),
  ]
}
