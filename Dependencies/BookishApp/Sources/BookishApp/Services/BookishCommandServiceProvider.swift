// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporterSamples
import BookishRecord
import BookishCapture
import Commands
import Foundation

/// Vends user-facing status reporting to commands that report successful work.
@MainActor
public protocol BookishStatusProvider: CommandCentre {
  /// The status service used by the command.
  var statusService: any BookishStatus { get }
}

/// Vends import presentation controls to import commands.
@MainActor
public protocol BookishImportPresentationProvider: CommandCentre {
  /// The import presentation used by the command.
  var importPresentation: any BookishImportPresentation { get }
}

/// Vends browser settings to browser-setting commands.
@MainActor
public protocol BookishBrowserSettingsProvider: CommandCentre {
  /// The browser settings service used by the command.
  var browserSettingsService: any BookishBrowserSettings { get }
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
  var recognitionService: any BookishRecognition { get }
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
  BookishBrowserSettingsProvider,
  BookishDatastoreMaintenanceProvider,
  BookishStorageProvider,
  BookishRecordActionsProvider,
  BookishRecognitionProvider,
  BookishNavigationProvider
{
}
