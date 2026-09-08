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

  /// Creates a command centre that vends the supplied Bookish service capabilities.
  public init(
    statusService: any BookishStatus,
    importPresentation: any BookishImportPresentation,
    datastoreMaintenanceService: any BookishDatastoreMaintenance,
    storageService: any BookishStorage,
    recordActionService: any BookishRecordActions,
    navigationService: any BookishNavigation
  ) {
    self.statusService = statusService
    self.importPresentation = importPresentation
    self.datastoreMaintenanceService = datastoreMaintenanceService
    self.storageService = storageService
    self.recordActionService = recordActionService
    self.navigationService = navigationService
  }

  /// Presents command failures through Bookish's user-facing status surface.
  public func recordCommandFailure<C: Command>(_ command: C, error: any Error)
  where C.Centre == BookishCommandCentre {
    statusService.report(error: error)
  }
}
