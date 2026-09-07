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

/// Vends user-facing status reporting to commands that report successful work.
@MainActor
public protocol BookishStatusReportingProvider: CommandCentre {
  /// The status reporting service used by the command.
  var statusReporter: any BookishStatusReporting { get }
}

/// Performs import actions requested by commands.
@MainActor
public protocol BookishImporting {
  /// Requests an interchange file import.
  func requestInterchangeImport()
  /// Requests a Delicious Library file import.
  func requestDeliciousLibraryImport()
  /// Imports a bundled Delicious Library sample.
  func importDeliciousLibrary(sample: DeliciousLibrarySample) async
}

/// Vends import actions to import commands.
@MainActor
public protocol BookishImportingProvider: CommandCentre {
  /// The import service used by the command.
  var importService: any BookishImporting { get }
}

/// Performs datastore maintenance actions requested by commands.
@MainActor
public protocol BookishDatastoreMaintenance {
  /// Whether records are available for interchange export.
  var hasExportableRecords: Bool { get }
  /// Requests interchange export.
  func requestInterchangeExport() async
  /// Reports a user-facing message.
  func report(message: String)
}

/// Vends datastore maintenance actions to maintenance commands.
@MainActor
public protocol BookishDatastoreMaintenanceProvider: CommandCentre {
  /// The datastore maintenance service used by the command.
  var datastoreMaintenanceService: any BookishDatastoreMaintenance { get }
}


/// Vends datastore operations to datastore commands.
@MainActor
public protocol BookishStorageProvider: CommandCentre {
  /// The datastore service used by the command.
  var storageService: any BookishStorage { get }
}

/// Performs selected-record actions requested by commands.
@MainActor
public protocol BookishRecordActions {
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
public protocol BookishRecordActionsProvider: CommandCentre {
  /// The record-action service used by the command.
  var recordActionService: any BookishRecordActions { get }
}

/// Performs browser index and record navigation requested by commands.
@MainActor
public protocol BookishNavigation {
  /// Whether another browser index is available.
  var canSelectAnotherRecordIndex: Bool { get }

  /// Whether another record is available in the selected browser index.
  var canSelectAnotherRecord: Bool { get }

  /// Selects a browser index and refreshes its displayed records.
  func select(recordIndexID: BookishRecordID?) async throws

  /// Selects the next browser index.
  func selectNextRecordIndex() async throws

  /// Selects the previous browser index.
  func selectPreviousRecordIndex() async throws

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

/// Vends browser navigation to navigation commands.
@MainActor
public protocol BookishNavigationProvider: CommandCentre {
  /// The browser navigation service.
  var navigationService: any BookishNavigation { get }
}

extension BookishCommandCentre:
  BookishStatusReportingProvider,
  BookishImportingProvider,
  BookishDatastoreMaintenanceProvider,
  BookishStorageProvider,
  BookishRecordActionsProvider,
  BookishNavigationProvider
{
}
