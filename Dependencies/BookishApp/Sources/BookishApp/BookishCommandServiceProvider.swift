// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporterSamples
import BookishRecord
import Commands
import Foundation

/// Reports user-facing Bookish status messages and errors.
@MainActor
public protocol BookishStatusReporting {
  /// Reports a user-facing message.
  func report(message: String)

  /// Reports a user-facing error.
  func report(error: Error)
}

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

/// Performs browser record navigation requested by commands.
@MainActor
public protocol BookishRecordNavigationService {
  /// Whether another record is available in the selected browser index.
  var canSelectAnotherRecord: Bool { get }

  /// Returns whether the selected browser index contains a record.
  func contains(recordID: BookishRecordID) -> Bool

  /// Pushes a record onto the detail navigation path.
  func push(recordID: BookishRecordID)

  /// Selects a record in the selected browser index.
  func select(recordID: BookishRecordID?)

  /// Selects the next record in the selected browser index.
  func selectNextRecord()

  /// Selects the previous record in the selected browser index.
  func selectPreviousRecord()
}

/// Vends browser record navigation to navigation commands.
@MainActor
public protocol BookishNavigationServiceProvider: CommandCentre {
  /// The browser record-navigation service.
  var navigationService: any BookishRecordNavigationService { get }
}

extension BookishCommandCentre:
  BookishImportServiceProvider,
  BookishDatastoreMaintenanceServiceProvider,
  BookishRecordActionServiceProvider,
  BookishBrowserIndexSelectionServiceProvider,
  BookishNavigationServiceProvider
{
}
