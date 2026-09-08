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
  /// The user-facing status service used for command-failure reporting.
  @ObservationIgnored public let statusService: any BookishStatus

  /// The import-presentation capability exposed to commands.
  @ObservationIgnored public let importPresentation: any BookishImportPresentation

  /// The datastore maintenance capability exposed to commands.
  @ObservationIgnored public let datastoreMaintenanceService: any BookishDatastoreMaintenance

  /// The datastore capability exposed to commands.
  @ObservationIgnored public let storageService: any BookishStorage

  /// The record-action capability exposed to commands.
  @ObservationIgnored public let recordActionService: any BookishRecordActions

  /// The browser navigation capability exposed to commands.
  @ObservationIgnored public let navigationService: any BookishNavigation

  /// Creates a command centre over the supplied Bookish services.
  public init(harness: BookishHarness) {
    statusService = harness.statusService
    importPresentation = harness
    datastoreMaintenanceService = harness
    storageService = harness.storageService
    recordActionService = BookishRecordActionsService(
      storage: harness.storageService,
      state: harness,
      statusService: harness.statusService
    )
    navigationService = harness.navigation
  }

  /// Presents command failures through Bookish's user-facing status surface.
  public func recordCommandFailure<C: Command>(_ command: C, error: any Error)
  where C.Centre == BookishCommandCentre {
    statusService.report(error: error)
  }
}
