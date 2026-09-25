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

  /// Command façade exposed to SwiftUI views.
  @ObservationIgnored let commander: BookishCommander

  /// Navigation and routing service for the datastore record browser.
  @ObservationIgnored public let navigation: BookishNavigationService

  /// Storage service that owns the loaded datastore.
  @ObservationIgnored public let storage: BookishStorageService

  /// Presentation service that owns layout and display configuration state.
  @ObservationIgnored public let presentation: BookishPresentationService

  /// Status service that owns user-visible progress, messages, and errors.
  @ObservationIgnored public let status: BookishStatusService

  /// Browser service that owns index visibility and browser refresh.
  @ObservationIgnored public let browser: BookishBrowserService

  /// Import workflow that reads, reviews, and applies imported records.
  @ObservationIgnored public let importing: BookishImportingService

  /// Export service that encodes records and presents the export sheet.
  @ObservationIgnored public let exporting: BookishExportingService

  /// Settings sheet presentation used by the iOS toolbar.
  @ObservationIgnored public let settingsPresentation: BookishSettingsPresentationService

  /// Record creation used by New commands.
  @ObservationIgnored let recordCreation: BookishRecordCreationService

  /// Record-action service used by selected-record commands.
  @ObservationIgnored let recordActions: BookishRecordActionsService

  /// Recognition workflow used by scanning controls and commands.
  @ObservationIgnored public let recognition: BookishRecognitionService

  /// Temporary metadata-lookup workflow exposed by the Lookup section.
  @ObservationIgnored public let lookup: BookishLookupWorkflowService

  /// Creates an engine with services backed by the supplied local datastore directory.
  public convenience init(
    directoryURL: URL? = nil,
    defaultShowsDebugIndexes: Bool = false
  ) {
    self.init(
      directoryURL: directoryURL,
      defaultShowsDebugIndexes: defaultShowsDebugIndexes,
      settings: .standard
    )
  }

  /// Creates an engine whose services persist their settings in the supplied defaults.
  init(
    directoryURL: URL?,
    defaultShowsDebugIndexes: Bool,
    settings defaults: UserDefaults
  ) {
    let storageService = BookishStorageService(directoryURL: directoryURL)
    let navigation = BookishNavigationService(storageService: storageService, settings: defaults)
    let presentationService = BookishPresentationService(storageService: storageService)
    let statusService = BookishStatusService()
    let browser = BookishBrowserService(
      navigation: navigation,
      presentation: presentationService,
      storage: storageService,
      statusService: statusService,
      defaultShowsDebugIndexes: defaultShowsDebugIndexes
    )
    let importing = BookishImportingService(
      storageService: storageService,
      navigation: navigation,
      browser: browser,
      statusService: statusService
    )
    let exporting = BookishExportingService(
      storageService: storageService,
      navigation: navigation,
      statusService: statusService
    )
    let recordCreation = BookishRecordCreationService(
      storage: storageService,
      navigation: navigation,
      browser: browser
    )
    let recordActions = BookishRecordActionsService(
      storage: storageService,
      navigation: navigation,
      browser: browser,
      statusService: statusService
    )
    let serviceConfiguration: BookishServiceConfiguration
    do {
      serviceConfiguration = try BookishServiceConfiguration.load()
    } catch {
      serviceConfiguration = BookishServiceConfiguration()
      statusService.report(error: error)
    }
    let recognition = BookishRecognitionService(
      storage: storageService,
      browser: browser,
      statusService: statusService,
      recognitionProviders: serviceConfiguration.recognitionProviders,
      settings: defaults
    )
    let lookup = BookishLookupWorkflowService(
      providers: serviceConfiguration.lookupProviders,
      settings: defaults
    )

    let commander = BookishCommander()
    state = .uninitialised
    startupTask = nil
    self.navigation = navigation
    self.storage = storageService
    self.presentation = presentationService
    self.status = statusService
    self.browser = browser
    self.importing = importing
    self.exporting = exporting
    self.settingsPresentation = BookishSettingsPresentationService()
    self.recordCreation = recordCreation
    self.commander = commander
    self.recordActions = recordActions
    self.recognition = recognition
    self.lookup = lookup

    commander.attach(to: self)
  }

  /// Applies application-owned service configuration without restarting the app.
  public func configureServices(_ configuration: BookishServiceConfiguration) async {
    recognition.configureRecognitionProviders(configuration.recognitionProviders)
    await lookup.configureProviders(configuration.lookupProviders)
  }

  /// Starts the standard shared application loop.
  public func start() {
    standardLoop()
  }

  /// Loads storage and refreshes the browser state for the application lifecycle.
  public func load() async {
    do {
      try await storage.load()
      try await browser.refresh()
      status.report(message: "Ready")
    } catch {
      status.report(error: error)
    }
  }

  /// Builds the root view managed by the shared application shell.
  public func rootContent() -> some View {
    rootView {
      BookishRootView()
    } startup: {
      ProgressView()
    }
  }
}

extension BookishEngine: CommandCentre {
  /// Vends user-facing status reporting to commands.
  public var statusService: any BookishStatusService.API {
    status
  }

  /// Vends datastore operations to commands.
  public var storageService: any BookishStorageService.API {
    storage
  }

  /// Vends browser navigation to commands.
  public var navigationService: any BookishNavigationService.API {
    navigation
  }

  /// Vends browser settings to commands.
  public var browserService: any BookishBrowserService.API {
    browser
  }

  /// Vends the import workflow to commands.
  public var importingService: any BookishImportingService.API {
    importing
  }

  /// Vends interchange export to commands.
  public var exportingService: any BookishExportingService.API {
    exporting
  }

  /// Vends settings sheet presentation to commands.
  public var settingsPresentationService: any BookishSettingsPresentationService.API {
    settingsPresentation
  }

  /// Vends record creation to New commands.
  public var recordCreationService: any BookishRecordCreationService.API {
    recordCreation
  }

  /// Vends selected-record actions to commands.
  public var recordActionsService: any BookishRecordActionsService.API {
    recordActions
  }

  /// Vends the scanning workflow to recognition commands.
  public var recognitionService: any BookishRecognitionService.API {
    recognition
  }

  /// Vends the lookup workflow to lookup-provider commands.
  public var lookupWorkflowService: any BookishLookupWorkflowService.API {
    lookup
  }

  /// Presents command failures through Bookish's user-facing status surface.
  public func recordCommandFailure<C: Command>(_ command: C, error: any Error)
  where C.Centre == BookishEngine {
    status.report(error: error)
  }
}
