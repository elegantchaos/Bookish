// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import Observation

/// The application-owned command boundary for Bookish services.
@MainActor
@Observable
public final class BookishCommandCentre: CommandCentre {
  /// The datastore-facing service used by record, import, and maintenance commands.
  @ObservationIgnored public let harness: BookishHarness

  /// The browser-routing service used by navigation commands.
  @ObservationIgnored public let navigationService: BookishNavigationService

  /// Creates a command centre over the supplied Bookish services.
  public init(harness: BookishHarness) {
    self.harness = harness
    navigationService = harness.navigation
  }

  /// Presents command failures through Bookish's user-facing status surface.
  public func recordCommandFailure<C: Command>(_ command: C, error: any Error)
  where C.Centre == BookishCommandCentre {
    harness.report(error: error)
  }
}
