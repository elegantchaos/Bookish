// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import BookishImporterSamples
import Foundation

/// Performs import actions requested by commands.
@MainActor
public protocol BookishImportService {
  /// Requests an interchange file import.
  func requestInterchangeImport()
  /// Requests a Delicious Library file import.
  func requestDeliciousLibraryImport()
  /// Imports a bundled Delicious Library sample.
  func importDeliciousLibrary(sample: DeliciousLibrarySample) async
}

/// Vends import actions to import commands.
@MainActor
public protocol BookishImportServiceProvider: CommandCentre {
  /// The import service used by the command.
  var importService: any BookishImportService { get }
}

/// Performs datastore maintenance actions requested by commands.
@MainActor
public protocol BookishDatastoreMaintenanceService {
  /// Whether records are available for interchange export.
  var hasExportableRecords: Bool { get }
  /// Requests interchange export.
  func requestInterchangeExport() async
  /// Returns the datastore directory.
  func localDatastoreDirectory() throws -> URL
  /// Reports a user-facing message.
  func report(message: String)
  /// Rebuilds the record projection.
  func rebuildRecordProjection() async
  /// Resets the datastore.
  func reset() async
}

/// Vends datastore maintenance actions to maintenance commands.
@MainActor
public protocol BookishDatastoreMaintenanceServiceProvider: CommandCentre {
  /// The datastore maintenance service used by the command.
  var datastoreMaintenanceService: any BookishDatastoreMaintenanceService { get }
}

/// Performs selected-record actions requested by commands.
@MainActor
public protocol BookishRecordActionService {
  /// Whether a record is selected.
  var hasSelectedRecord: Bool { get }
  /// Marks the selected record as reading.
  func markReading() async
  /// Marks the selected record as finished.
  func markFinished() async
  /// Simulates a remote update.
  func simulateRemoteUpdate() async
}

/// Vends selected-record actions to record commands.
@MainActor
public protocol BookishRecordActionServiceProvider: CommandCentre {
  /// The record-action service used by the command.
  var recordActionService: any BookishRecordActionService { get }
}

/// Performs browser-index selection requested by commands.
@MainActor
public protocol BookishBrowserIndexSelectionService {
  /// Whether another index can be selected.
  var canSelectAnotherRecordIndex: Bool { get }
  /// Selects the next browser index.
  func selectNextRecordIndex() async
  /// Selects the previous browser index.
  func selectPreviousRecordIndex() async
}

/// Vends browser-index selection to index commands.
@MainActor
public protocol BookishBrowserIndexSelectionServiceProvider: CommandCentre {
  /// The browser-index selection service used by the command.
  var browserIndexSelectionService: any BookishBrowserIndexSelectionService { get }
}

/// Vends browser routing to navigation commands.
@MainActor
public protocol BookishNavigationServiceProvider: CommandCentre {
  /// The browser-routing service.
  var navigationService: BookishNavigationService { get }
}

extension BookishCommandCentre:
  BookishImportServiceProvider,
  BookishDatastoreMaintenanceServiceProvider,
  BookishRecordActionServiceProvider,
  BookishBrowserIndexSelectionServiceProvider,
  BookishNavigationServiceProvider
{
  /// The import capability exposed to commands.
  public var importService: any BookishImportService { harness }
  /// The datastore maintenance capability exposed to commands.
  public var datastoreMaintenanceService: any BookishDatastoreMaintenanceService { harness }
  /// The record action capability exposed to commands.
  public var recordActionService: any BookishRecordActionService { harness }
  /// The browser-index selection capability exposed to commands.
  public var browserIndexSelectionService: any BookishBrowserIndexSelectionService { harness }
}
