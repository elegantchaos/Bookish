// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishLookup

/// Defines the lookup-provider selection actions exposed to commands.
@MainActor
public protocol BookishLookupWorkflow: AnyObject {
  /// Whether the current query can be submitted.
  var canLookupBooks: Bool { get }

  /// Submits the current query to the selected provider.
  func lookupBooks() async

  /// Whether a lookup request is currently underway.
  var isLookingUp: Bool { get }

  /// Selects the lookup provider used by subsequent requests.
  func selectProvider(_ providerID: BookLookupProviderID)

  /// Returns whether the identified provider can execute requests.
  func isProviderSupported(_ providerID: BookLookupProviderID) -> Bool
}
