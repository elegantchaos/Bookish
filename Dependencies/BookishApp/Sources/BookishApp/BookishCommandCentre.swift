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
  /// The datastore coordinator used for command-failure reporting.
  @ObservationIgnored private let harness: BookishHarness

  /// The import capability exposed to commands.
  @ObservationIgnored public let importService: any BookishImportService

  /// The datastore maintenance capability exposed to commands.
  @ObservationIgnored public let datastoreMaintenanceService: any BookishDatastoreMaintenanceService

  /// The record-action capability exposed to commands.
  @ObservationIgnored public let recordActionService: any BookishRecordActionService

  /// The browser-index selection capability exposed to commands.
  @ObservationIgnored public let browserIndexSelectionService: any BookishBrowserIndexSelectionService

  /// The browser-routing service used by navigation commands.
  @ObservationIgnored public let navigationService: BookishNavigationService

  /// Creates a command centre over the supplied Bookish services.
  public init(harness: BookishHarness) {
    self.harness = harness
    importService = harness
    datastoreMaintenanceService = harness
    recordActionService = harness
    browserIndexSelectionService = harness
    navigationService = harness.navigation
  }

  /// Presents command failures through Bookish's user-facing status surface.
  public func recordCommandFailure<C: Command>(_ command: C, error: any Error)
  where C.Centre == BookishCommandCentre {
    harness.report(error: error)
  }
}
