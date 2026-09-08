// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Application
import Observation
import SwiftUI

/// Application-shell engine for the datastore.
///
/// The engine lets the datastore use the shared `Application` startup state
/// machine while owning Bookish's concrete services.
@MainActor
@Observable
public final class BookishEngine {
  /// Current state of the shared application loop.
  public var state: AppState

  /// Startup task owned by the shared application loop.
  @ObservationIgnored public var startupTask: Task<Void, Never>?

  /// Global UI state used by the Bookish UI and commands.
  @ObservationIgnored public let uiState: BookishUIStateService

  /// Application-owned command boundary for Bookish services.
  @ObservationIgnored public let commander: BookishCommandCentre

  /// Navigation and routing service for the datastore record browser.
  @ObservationIgnored public let navigation: BookishNavigationService

  /// Storage service that owns the loaded datastore.
  @ObservationIgnored public let storageService: BookishStorageService

  /// Presentation service that owns layout and display configuration state.
  @ObservationIgnored public let presentationService: BookishPresentationService

  /// Status service that owns user-visible progress, messages, and errors.
  @ObservationIgnored public let statusService: BookishStatusService

  /// Import service that persists imported model records.
  @ObservationIgnored public let importingService: BookishImportingService

  /// Export service that encodes model records for export.
  @ObservationIgnored public let exportingService: BookishExportingService

  /// Creates an engine with services backed by the supplied local datastore directory.
  public init(
    directoryURL: URL? = nil,
    defaultShowsDebugIndexes: Bool = false
  ) {
    let storageService = BookishStorageService(directoryURL: directoryURL)
    let navigation = BookishNavigationService(storageService: storageService)
    let presentationService = BookishPresentationService(storageService: storageService)
    let statusService = BookishStatusService()
    let importingService = BookishImportingService(storageService: storageService)
    let exportingService = BookishExportingService(storageService: storageService)
    let uiState = BookishUIStateService(
      navigation: navigation,
      presentation: presentationService,
      statusService: statusService,
      importingService: importingService,
      exportingService: exportingService,
      defaultShowsDebugIndexes: defaultShowsDebugIndexes
    )
    let recordActionService = BookishRecordActionsService(
      storage: storageService,
      state: uiState,
      statusService: statusService
    )
    state = .uninitialised
    startupTask = nil
    self.navigation = navigation
    self.storageService = storageService
    self.presentationService = presentationService
    self.statusService = statusService
    self.importingService = importingService
    self.exportingService = exportingService
    self.uiState = uiState
    commander = BookishCommandCentre(
      statusService: statusService,
      importPresentation: uiState,
      datastoreMaintenanceService: uiState,
      storageService: storageService,
      recordActionService: recordActionService,
      navigationService: navigation
    )
  }

  /// Starts the standard shared application loop.
  public func start() {
    standardLoop()
  }

  /// Builds the root view managed by the shared application shell.
  public func rootContent() -> some View {
    rootView {
      BookishUIStateView(uiState: uiState, loadsOnAppear: false)
    } startup: {
      ProgressView()
    }
  }
}
