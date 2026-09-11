// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporterSamples
import BookishRecord
import Commands
import Foundation

/// Vends user-facing status reporting to commands that report successful work.
@MainActor
public protocol BookishStatusProvider: CommandCentre {
  /// The status service used by the command.
  var statusService: any BookishStatus { get }
}

/// Presents import controls requested by commands.
@MainActor
public protocol BookishImportPresentation {
  /// Requests an interchange file import.
  func requestInterchangeImport()
  /// Requests a Delicious Library file import.
  func requestDeliciousLibraryImport()
  /// Imports a bundled Delicious Library sample.
  func importDeliciousLibrary(sample: DeliciousLibrarySample) async
}

/// Vends import presentation controls to import commands.
@MainActor
public protocol BookishImportPresentationProvider: CommandCentre {
  /// The import presentation used by the command.
  var importPresentation: any BookishImportPresentation { get }
}

/// Performs datastore maintenance actions requested by commands.
@MainActor
public protocol BookishDatastoreMaintenance {
  /// Whether records are available for interchange export.
  var hasExportableRecords: Bool { get }
  /// Requests interchange export.
  func requestInterchangeExport() async
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

/// Vends the scanning workflow used by recognition commands.
@MainActor
public protocol BookishRecognitionProvider: CommandCentre {
  /// The recognition workflow used by the command.
  var recognitionService: any BookishRecognitionWorkflow { get }
}

/// Vends browser navigation to navigation commands.
@MainActor
public protocol BookishNavigationProvider: CommandCentre {
  /// The browser navigation service.
  var navigationService: any BookishNavigation { get }
}

extension BookishEngine:
  BookishStatusProvider,
  BookishImportPresentationProvider,
  BookishDatastoreMaintenanceProvider,
  BookishStorageProvider,
  BookishRecordActionsProvider,
  BookishRecognitionProvider,
  BookishNavigationProvider
{
}
