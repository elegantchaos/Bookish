// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Carries one provider's completed work through the lookup task group.
enum ProviderResult: Sendable {
  /// The candidates returned by a provider.
  case success([BookLookupCandidate])

  /// The error returned by a provider.
  case failure(BookLookupFailure)
}
