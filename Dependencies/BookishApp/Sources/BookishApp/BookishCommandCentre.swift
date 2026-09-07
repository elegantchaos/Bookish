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
  /// The user-facing status capability used for command-failure reporting.
  @ObservationIgnored public let statusReporter: any BookishStatusReporting

  /// The import capability exposed to commands.
  @ObservationIgnored public let importService: any BookishImportService

  /// The datastore maintenance capability exposed to commands.
  @ObservationIgnored public let datastoreMaintenanceService: any BookishDatastoreMaintenanceService

  /// The record-action capability exposed to commands.
  @ObservationIgnored public let recordActionService: any BookishRecordActionService

  /// The browser-index selection capability exposed to commands.
  @ObservationIgnored public let browserIndexSelectionService:
    any BookishBrowserIndexSelectionService

  /// The browser record-navigation capability exposed to commands.
  @ObservationIgnored public let navigationService: any BookishRecordNavigationService

  /// Creates a command centre over the supplied Bookish services.
  public init(harness: BookishHarness) {
    statusReporter = harness
    importService = harness
    datastoreMaintenanceService = harness
    recordActionService = BookishRecordActions(store: harness)
    browserIndexSelectionService = harness
    navigationService = harness.navigation
  }

  /// Presents command failures through Bookish's user-facing status surface.
  public func recordCommandFailure<C: Command>(_ command: C, error: any Error)
  where C.Centre == BookishCommandCentre {
    statusReporter.report(error: error)
  }
}
