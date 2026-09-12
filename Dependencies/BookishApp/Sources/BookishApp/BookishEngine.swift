// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Application
import Commands
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

  /// Command façade exposed to SwiftUI views.
  @ObservationIgnored let commander: BookishCommander

  /// Navigation and routing service for the datastore record browser.
  @ObservationIgnored public let navigation: BookishNavigationService

  /// Storage service that owns the loaded datastore.
  @ObservationIgnored public let storage: BookishStorageService

  /// Presentation service that owns layout and display configuration state.
  @ObservationIgnored public let presentationService: BookishPresentationService

  /// Status service that owns user-visible progress, messages, and errors.
  @ObservationIgnored public let status: BookishStatusService

  /// Import service that persists imported model records.
  @ObservationIgnored public let importingService: BookishImportingService

  /// Export service that encodes model records for export.
  @ObservationIgnored public let exportingService: BookishExportingService

  /// Record-action service used by selected-record commands.
  @ObservationIgnored private let recordActions: BookishRecordActionsService

  /// Recognition workflow used by scanning controls and commands.
  @ObservationIgnored public let recognition: BookishRecognitionService

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
    let recordActions = BookishRecordActionsService(
      storage: storageService,
      state: uiState,
      statusService: statusService
    )
    let recognition = BookishRecognitionService(
      storage: storageService,
      state: uiState,
      statusService: statusService
    )
    
    let commander = BookishCommander()
    state = .uninitialised
    startupTask = nil
    self.navigation = navigation
    self.storage = storageService
    self.presentationService = presentationService
    self.status = statusService
    self.importingService = importingService
    self.exportingService = exportingService
    self.uiState = uiState
    self.commander = commander
    self.recordActions = recordActions
    self.recognition = recognition

    commander.attach(to: self)
  }

  /// Starts the standard shared application loop.
  public func start() {
    standardLoop()
  }

  /// Loads storage and refreshes the browser state for the application lifecycle.
  public func load() async {
    do {
      try await storage.load()
      try await uiState.refreshBrowser()
      status.report(message: "Ready")
    } catch {
      status.report(error: error)
    }
  }

  /// Builds the root view managed by the shared application shell.
  public func rootContent() -> some View {
    rootView {
      BookishUIStateView()
    } startup: {
      ProgressView()
    }
  }
}

extension BookishEngine: CommandCentre {
  /// Vends user-facing status reporting to commands.
  public var statusService: any BookishStatus {
    status
  }

  /// Vends datastore operations to commands.
  public var storageService: any BookishStorage {
    storage
  }

  /// Vends browser navigation to commands.
  public var navigationService: any BookishNavigation {
    navigation
  }

  /// Vends import presentation controls to commands.
  public var importPresentation: any BookishImportPresentation {
    uiState
  }

  /// Vends browser settings to commands.
  public var browserSettingsService: any BookishBrowserSettings {
    uiState
  }

  /// Vends datastore-maintenance presentation controls to commands.
  public var datastoreMaintenanceService: any BookishDatastoreMaintenance {
    uiState
  }

  /// Vends selected-record actions to commands.
  public var recordActionService: any BookishRecordActions {
    recordActions
  }

  /// Vends the scanning workflow to recognition commands.
  public var recognitionService: any BookishRecognition {
    recognition
  }

  /// Presents command failures through Bookish's user-facing status surface.
  public func recordCommandFailure<C: Command>(_ command: C, error: any Error)
  where C.Centre == BookishEngine {
    status.report(error: error)
  }
}
