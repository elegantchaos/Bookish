// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Records one provider failure without discarding results from other providers.
public struct BookLookupFailure: Sendable {
  /// The provider that could not complete the lookup.
  public let providerID: BookLookupProviderID

  /// The underlying provider error.
  public let error: any Error

  /// Creates a provider-specific failure.
  public init(providerID: BookLookupProviderID, error: any Error) {
    self.providerID = providerID
    self.error = error
  }
}
