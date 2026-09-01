import BookishImporter
import BookishImporterSamples
import BookishRecord
import Commands
import CommandsUI
import Foundation
import Icons
import SwiftUI

#if canImport(AppKit)
  import AppKit
#endif

/// macOS menu commands for the datastore prototype.
public struct DatastorePrototypeCommands: Commands {
  private let harness: DatastorePrototypeHarness
  private let navigation: DatastorePrototypeNavigationService

  #if DEBUG
    @Environment(\.openWindow) private var openWindow
  #endif

  /// Creates commands bound to a prototype harness.
  public init(harness: DatastorePrototypeHarness, navigation: DatastorePrototypeNavigationService) {
    self.harness = harness
    self.navigation = navigation
  }

  public var body: some Commands {
    CommandGroup(after: .newItem) {
      harness.button(ImportInterchangeCommand())
      Menu("Import Delicious Library") {
        harness.button(ImportDeliciousLibrarySampleCommand(sample: .small))
        harness.button(ImportDeliciousLibrarySampleCommand(sample: .full))

        Divider()

        harness.button(ImportOtherDeliciousLibraryCommand())
      }

      Divider()

      harness.button(ExportInterchangeCommand())
      harness.button(RevealDatastoreFolderCommand())

      Divider()

      harness.button(ResetPrototypeCommand(), role: .destructive)
    }

    CommandMenu("Prototype") {
      harness.button(MarkReadingCommand())
      harness.button(MarkFinishedCommand())

      Divider()

      harness.button(SimulateRemoteMutationCommand())

      Divider()

      navigation.button(SelectPreviousRecordKindCommand())
      navigation.button(SelectNextRecordKindCommand())
      navigation.button(SelectPreviousRecordCommand())
      navigation.button(SelectNextRecordCommand())

      #if DEBUG
        Divider()

        harness.button(ThrowTestErrorCommand())

        Button("Show Mutation Debug Window") {
          openWindow(id: DatastorePrototypeWindow.mutationDebug.rawValue)
        }
      #endif
    }
  }
}

/// Window identifiers used by the prototype app scenes.
public enum DatastorePrototypeWindow: String, Sendable {
  /// Debug-only mutation history browser.
  case mutationDebug = "datastore-prototype-mutation-debug"
}

#if DEBUG
  /// Error emitted by the prototype command used to exercise user-facing error reporting.
  private enum PrototypeTestCommandError: LocalizedError {
    /// The deliberate failure case.
    case intentional

    /// Explains that the error was triggered by the diagnostic command.
    var errorDescription: String? {
      "This is a test command error."
    }
  }

  /// Deliberately fails so the prototype can verify command error presentation.
  public struct ThrowTestErrorCommand: CommandWithUI {
    public typealias Centre = DatastorePrototypeHarness
    public typealias ResultType = Void

    public let id = "datastore.throw-test-error"

    /// Creates the diagnostic command.
    public init() {
    }

    public func name(centre: DatastorePrototypeHarness) -> String {
      "Throw Test Error"
    }

    public func icon(centre: DatastorePrototypeHarness) -> Icon {
      Icon("exclamationmark.triangle")
    }

    public func help(centre: DatastorePrototypeHarness) -> String? {
      "Tests whether a command failure appears in the status bar."
    }

    public func perform(centre: DatastorePrototypeHarness) async throws {
      throw PrototypeTestCommandError.intentional
    }
  }
#endif

/// Reveals the prototype datastore folder in Finder.
public struct RevealDatastoreFolderCommand: CommandWithUI {
  public typealias Centre = DatastorePrototypeHarness
  public typealias ResultType = Void

  public let id = "datastore.reveal-folder"

  public init() {
  }

  public func availability(centre: DatastorePrototypeHarness) -> CommandAvailability {
    #if canImport(AppKit)
      .enabled
    #else
      .disabled
    #endif
  }

  public func name(centre: DatastorePrototypeHarness) -> String {
    "Reveal Datastore Folder"
  }

  public func icon(centre: DatastorePrototypeHarness) -> Icon {
    Icon("folder")
  }

  public func help(centre: DatastorePrototypeHarness) -> String? {
    "Reveal the local prototype datastore folder in Finder."
  }

  public func perform(centre: DatastorePrototypeHarness) async throws {
    #if canImport(AppKit)
      let url = try centre.localDatastoreDirectory()
      NSWorkspace.shared.activateFileViewerSelecting([url])
      centre.report(message: "Revealed datastore folder")
    #else
      centre.report(message: "Reveal datastore folder is unavailable on this platform")
    #endif
  }
}

extension DatastorePrototypeHarness: CommandCentre {
  /// Displays fire-and-forget command failures in the prototype status bar.
  public func recordCommandFailure<C: Command>(_ command: C, error: any Error)
  where C.Centre == DatastorePrototypeHarness {
    report(error: error)
  }
}

/// Requests an interchange JSON import through the view-owned file picker.
public struct ImportInterchangeCommand: CommandWithUI {
  public typealias Centre = DatastorePrototypeHarness
  public typealias ResultType = Void

  public let id = "datastore.import.interchange"
  public var shortcut: CommandShortcut? { .init("i", modifiers: [.command, .shift]) }

  public init() {
  }

  public func name(centre: DatastorePrototypeHarness) -> String {
    "Import Interchange File..."
  }

  public func icon(centre: DatastorePrototypeHarness) -> Icon {
    Icon("square.and.arrow.down")
  }

  public func help(centre: DatastorePrototypeHarness) -> String? {
    "Import records from a Bookish interchange JSON file."
  }

  public func perform(centre: DatastorePrototypeHarness) async throws {
    centre.requestInterchangeImport()
  }
}

/// Imports one of Bookish's bundled Delicious Library samples.
public struct ImportDeliciousLibrarySampleCommand: CommandWithUI {
  public typealias Centre = DatastorePrototypeHarness
  public typealias ResultType = Void

  /// The bundled sample to import.
  public let sample: DeliciousLibrarySample

  /// Creates a command for a bundled Delicious Library sample.
  public init(sample: DeliciousLibrarySample) {
    self.sample = sample
  }

  public var id: String {
    "datastore.import.delicious-library.\(sample.rawValue)"
  }

  public func name(centre: DatastorePrototypeHarness) -> String {
    switch sample {
    case .small:
      "Small Sample"
    case .full:
      "Full Sample"
    }
  }

  public func icon(centre: DatastorePrototypeHarness) -> Icon {
    Icon("books.vertical")
  }

  public func help(centre: DatastorePrototypeHarness) -> String? {
    "Import the bundled \(name(centre: centre)) Delicious Library XML export."
  }

  public func perform(centre: DatastorePrototypeHarness) async throws {
    await centre.importDeliciousLibrary(sample: sample)
  }
}

/// Requests a Delicious Library import through the view-owned file picker.
public struct ImportOtherDeliciousLibraryCommand: CommandWithUI {
  public typealias Centre = DatastorePrototypeHarness
  public typealias ResultType = Void

  public let id = "datastore.import.delicious-library.other"

  public init() {
  }

  public func name(centre: DatastorePrototypeHarness) -> String {
    "Other…"
  }

  public func icon(centre: DatastorePrototypeHarness) -> Icon {
    Icon("books.vertical")
  }

  public func help(centre: DatastorePrototypeHarness) -> String? {
    "Import records from another Delicious Library XML export."
  }

  public func perform(centre: DatastorePrototypeHarness) async throws {
    centre.requestDeliciousLibraryImport()
  }
}

/// Exports the materialised records as Bookish interchange JSON.
public struct ExportInterchangeCommand: CommandWithUI {
  public typealias Centre = DatastorePrototypeHarness
  public typealias ResultType = Void

  public let id = "datastore.export.interchange"
  public var shortcut: CommandShortcut? { .init("e", modifiers: [.command, .shift]) }

  public init() {
  }

  public func availability(centre: DatastorePrototypeHarness) -> CommandAvailability {
    centre.navigation.recordIDs.isEmpty ? .disabled : .enabled
  }

  public func name(centre: DatastorePrototypeHarness) -> String {
    "Export Interchange File..."
  }

  public func icon(centre: DatastorePrototypeHarness) -> Icon {
    Icon("square.and.arrow.up")
  }

  public func help(centre: DatastorePrototypeHarness) -> String? {
    "Export the current materialised records as Bookish interchange JSON."
  }

  public func perform(centre: DatastorePrototypeHarness) async throws {
    await centre.requestInterchangeExport()
  }
}

/// Clears all prototype records and mutations.
public struct ResetPrototypeCommand: CommandWithUI {
  public typealias Centre = DatastorePrototypeHarness
  public typealias ResultType = Void

  public let id = "datastore.reset"

  public init() {
  }

  public func name(centre: DatastorePrototypeHarness) -> String {
    "Reset Prototype Datastore"
  }

  public func icon(centre: DatastorePrototypeHarness) -> Icon {
    Icon("trash")
  }

  public func help(centre: DatastorePrototypeHarness) -> String? {
    "Remove every record and mutation from the prototype datastore."
  }

  public func confirmation(centre: DatastorePrototypeHarness) -> CommandConfirmation? {
    CommandConfirmation(
      title: "Reset Prototype Datastore?",
      cancel: "Cancel",
      message: "This removes every record and mutation from the prototype datastore.",
      confirm: "Reset"
    )
  }

  public func perform(centre: DatastorePrototypeHarness) async throws {
    await centre.reset()
  }
}

/// Marks the selected record as currently being read.
public struct MarkReadingCommand: CommandWithUI {
  public typealias Centre = DatastorePrototypeHarness
  public typealias ResultType = Void

  public let id = "datastore.mark-reading"
  public var shortcut: CommandShortcut? { .init("r", modifiers: [.command, .shift]) }

  public init() {
  }

  public func availability(centre: DatastorePrototypeHarness) -> CommandAvailability {
    centre.navigation.selectedRecordID == nil ? .disabled : .enabled
  }

  public func name(centre: DatastorePrototypeHarness) -> String {
    "Mark Reading"
  }

  public func icon(centre: DatastorePrototypeHarness) -> Icon {
    Icon("book")
  }

  public func help(centre: DatastorePrototypeHarness) -> String? {
    "Mark the selected record as currently being read."
  }

  public func perform(centre: DatastorePrototypeHarness) async throws {
    await centre.markReading()
  }
}

/// Marks the selected record as finished.
public struct MarkFinishedCommand: CommandWithUI {
  public typealias Centre = DatastorePrototypeHarness
  public typealias ResultType = Void

  public let id = "datastore.mark-finished"
  public var shortcut: CommandShortcut? { .init("f", modifiers: [.command, .shift]) }

  public init() {
  }

  public func availability(centre: DatastorePrototypeHarness) -> CommandAvailability {
    centre.navigation.selectedRecordID == nil ? .disabled : .enabled
  }

  public func name(centre: DatastorePrototypeHarness) -> String {
    "Mark Finished"
  }

  public func icon(centre: DatastorePrototypeHarness) -> Icon {
    Icon("checkmark.circle")
  }

  public func help(centre: DatastorePrototypeHarness) -> String? {
    "Mark the selected record as finished."
  }

  public func perform(centre: DatastorePrototypeHarness) async throws {
    await centre.markFinished()
  }
}

/// Applies a synthetic remote mutation to the selected record.
public struct SimulateRemoteMutationCommand: CommandWithUI {
  public typealias Centre = DatastorePrototypeHarness
  public typealias ResultType = Void

  public let id = "datastore.simulate-remote-mutation"

  public init() {
  }

  public func availability(centre: DatastorePrototypeHarness) -> CommandAvailability {
    centre.navigation.selectedRecordID == nil ? .disabled : .enabled
  }

  public func name(centre: DatastorePrototypeHarness) -> String {
    "Simulate Remote Mutation"
  }

  public func icon(centre: DatastorePrototypeHarness) -> Icon {
    Icon("arrow.triangle.2.circlepath")
  }

  public func help(centre: DatastorePrototypeHarness) -> String? {
    "Apply a synthetic remote mutation to the selected record."
  }

  public func perform(centre: DatastorePrototypeHarness) async throws {
    await centre.simulateRemoteUpdate()
  }
}

/// Selects the next record kind in the prototype browser.
public struct SelectNextRecordKindCommand: CommandWithUI {
  public typealias Centre = DatastorePrototypeNavigationService
  public typealias ResultType = Void

  public let id = "datastore.navigation.next-kind"
  public var shortcut: CommandShortcut? { .init(.rightArrow, modifiers: [.command, .option]) }

  public init() {
  }

  public func availability(centre: DatastorePrototypeNavigationService) -> CommandAvailability {
    centre.recordKinds.count > 1 ? .enabled : .disabled
  }

  public func name(centre: DatastorePrototypeNavigationService) -> String {
    "Next Record Type"
  }

  public func icon(centre: DatastorePrototypeNavigationService) -> Icon {
    Icon("sidebar.right")
  }

  public func help(centre: DatastorePrototypeNavigationService) -> String? {
    "Select the next record type in the prototype browser."
  }

  public func perform(centre: DatastorePrototypeNavigationService) async throws {
    centre.selectNextKind()
  }
}

/// Selects the previous record kind in the prototype browser.
public struct SelectPreviousRecordKindCommand: CommandWithUI {
  public typealias Centre = DatastorePrototypeNavigationService
  public typealias ResultType = Void

  public let id = "datastore.navigation.previous-kind"
  public var shortcut: CommandShortcut? { .init(.leftArrow, modifiers: [.command, .option]) }

  public init() {
  }

  public func availability(centre: DatastorePrototypeNavigationService) -> CommandAvailability {
    centre.recordKinds.count > 1 ? .enabled : .disabled
  }

  public func name(centre: DatastorePrototypeNavigationService) -> String {
    "Previous Record Type"
  }

  public func icon(centre: DatastorePrototypeNavigationService) -> Icon {
    Icon("sidebar.left")
  }

  public func help(centre: DatastorePrototypeNavigationService) -> String? {
    "Select the previous record type in the prototype browser."
  }

  public func perform(centre: DatastorePrototypeNavigationService) async throws {
    centre.selectPreviousKind()
  }
}

/// Selects the next record in the active prototype browser index.
public struct SelectNextRecordCommand: CommandWithUI {
  public typealias Centre = DatastorePrototypeNavigationService
  public typealias ResultType = Void

  public let id = "datastore.navigation.next-record"
  public var shortcut: CommandShortcut? { .init(.downArrow, modifiers: [.command, .option]) }

  public init() {
  }

  public func availability(centre: DatastorePrototypeNavigationService) -> CommandAvailability {
    centre.selectedRecordIDs.count > 1 ? .enabled : .disabled
  }

  public func name(centre: DatastorePrototypeNavigationService) -> String {
    "Next Record"
  }

  public func icon(centre: DatastorePrototypeNavigationService) -> Icon {
    Icon("arrow.down")
  }

  public func help(centre: DatastorePrototypeNavigationService) -> String? {
    "Select the next record in the active prototype browser index."
  }

  public func perform(centre: DatastorePrototypeNavigationService) async throws {
    centre.selectNextRecord()
  }
}

/// Selects the previous record in the active prototype browser index.
public struct SelectPreviousRecordCommand: CommandWithUI {
  public typealias Centre = DatastorePrototypeNavigationService
  public typealias ResultType = Void

  public let id = "datastore.navigation.previous-record"
  public var shortcut: CommandShortcut? { .init(.upArrow, modifiers: [.command, .option]) }

  public init() {
  }

  public func availability(centre: DatastorePrototypeNavigationService) -> CommandAvailability {
    centre.selectedRecordIDs.count > 1 ? .enabled : .disabled
  }

  public func name(centre: DatastorePrototypeNavigationService) -> String {
    "Previous Record"
  }

  public func icon(centre: DatastorePrototypeNavigationService) -> Icon {
    Icon("arrow.up")
  }

  public func help(centre: DatastorePrototypeNavigationService) -> String? {
    "Select the previous record in the active prototype browser index."
  }

  public func perform(centre: DatastorePrototypeNavigationService) async throws {
    centre.selectPreviousRecord()
  }
}

/// Navigates directly to a materialised record in the prototype browser.
public struct NavigateToRecordCommand: CommandWithUI {
  public typealias Centre = DatastorePrototypeNavigationService
  public typealias ResultType = Void

  public let id: String
  private let recordID: BookishRecordID

  /// Creates a record navigation command for a specific target.
  public init(recordID: BookishRecordID) {
    self.id = "datastore.navigation.record.\(recordID.rawValue)"
    self.recordID = recordID
  }

  public func availability(centre: DatastorePrototypeNavigationService) -> CommandAvailability {
    centre.contains(recordID: recordID) ? .enabled : .disabled
  }

  public func name(centre: DatastorePrototypeNavigationService) -> String {
    "Go to Record"
  }

  public func icon(centre: DatastorePrototypeNavigationService) -> Icon {
    Icon("arrow.right.circle")
  }

  public func help(centre: DatastorePrototypeNavigationService) -> String? {
    "Navigate to the linked record."
  }

  public func perform(centre: DatastorePrototypeNavigationService) async throws {
    centre.select(recordID: recordID)
  }
}
