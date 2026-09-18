// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Defines an adapter that retrieves book metadata from one source.
public protocol BookLookupProvider: Sendable, Identifiable where ID == String {
  /// The stable identifier used for provenance and provider selection.
  var id: String { get }

  /// The user-facing provider name.
  var label: String { get }

  /// A user-facing explanation of the provider's coverage or behavior.
  var description: String { get }

  /// Whether this provider can run on the current device.
  var isSupported: Bool { get }

  /// Returns metadata candidates matching a query.
  func lookupBooks(matching query: BookLookupQuery) async throws -> [BookLookupCandidate]
}

extension BookLookupProvider {
  /// Indicates that providers without platform requirements are supported.
  public var isSupported: Bool { true }
}
