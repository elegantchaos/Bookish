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

/// macOS menu commands for the datastore.
public struct BookishCommands: Commands {
  private let harness: BookishHarness
  private let navigation: BookishNavigationService

  #if DEBUG
    @Environment(\.openWindow) private var openWindow
  #endif

  /// Creates commands bound to a datastore harness.
  public init(harness: BookishHarness, navigation: BookishNavigationService) {
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

      harness.button(RebuildRecordStoreCommand())
      harness.button(ResetDatastoreCommand(), role: .destructive)
    }

    CommandMenu("Bookish") {
      harness.button(MarkReadingCommand())
      harness.button(MarkFinishedCommand())

      Divider()

      harness.button(SimulateRemoteMutationCommand())

      Divider()

      harness.button(SelectPreviousRecordIndexCommand())
      harness.button(SelectNextRecordIndexCommand())
      navigation.button(SelectPreviousRecordCommand())
      navigation.button(SelectNextRecordCommand())

      #if DEBUG
        Divider()

        harness.button(ThrowTestErrorCommand())

        Button("Show Mutation Debug Window") {
          openWindow(id: BookishWindow.mutationDebug.rawValue)
        }
      #endif
    }
  }
}

/// Window identifiers used by the datastore app scenes.
public enum BookishWindow: String, Sendable {
  /// The primary Bookish browser window.
  case main = "bookish-main"

  /// Debug-only mutation history browser.
  case mutationDebug = "bookish-mutation-debug"
}

#if DEBUG
  /// Error emitted by the datastore command used to exercise user-facing error reporting.
  private enum BookishTestCommandError: LocalizedError {
    /// The deliberate failure case.
    case intentional

    /// Explains that the error was triggered by the diagnostic command.
    var errorDescription: String? {
      "This is a test command error."
    }
  }

  /// Deliberately fails so the datastore can verify command error presentation.
  public struct ThrowTestErrorCommand: CommandWithUI {
    public typealias Centre = BookishHarness
    public typealias ResultType = Void

    public let id = "datastore.throw-test-error"

    /// Creates the diagnostic command.
    public init() {
    }

    public func name(centre: BookishHarness) -> String {
      "Throw Test Error"
    }

    public func icon(centre: BookishHarness) -> Icon {
      Icon("exclamationmark.triangle")
    }

    public func help(centre: BookishHarness) -> String? {
      "Tests whether a command failure appears in the status bar."
    }

    public func perform(centre: BookishHarness) async throws {
      throw BookishTestCommandError.intentional
    }
  }
#endif

/// Reveals the datastore folder in Finder.
public struct RevealDatastoreFolderCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.reveal-folder"

  public init() {
  }

  public func availability(centre: BookishHarness) -> CommandAvailability {
    #if canImport(AppKit)
      .enabled
    #else
      .disabled
    #endif
  }

  public func name(centre: BookishHarness) -> String {
    "Reveal Datastore Folder"
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("folder")
  }

  public func help(centre: BookishHarness) -> String? {
    "Reveal the local datastore folder in Finder."
  }

  public func perform(centre: BookishHarness) async throws {
    #if canImport(AppKit)
      let url = try centre.localDatastoreDirectory()
      NSWorkspace.shared.activateFileViewerSelecting([url])
      centre.report(message: "Revealed datastore folder")
    #else
      centre.report(message: "Reveal datastore folder is unavailable on this platform")
    #endif
  }
}

extension BookishHarness: CommandCentre {
  /// Displays fire-and-forget command failures in the datastore status bar.
  public func recordCommandFailure<C: Command>(_ command: C, error: any Error)
  where C.Centre == BookishHarness {
    report(error: error)
  }
}

/// Requests an interchange JSON import through the view-owned file picker.
public struct ImportInterchangeCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.import.interchange"
  public var shortcut: CommandShortcut? { .init("i", modifiers: [.command, .shift]) }

  public init() {
  }

  public func name(centre: BookishHarness) -> String {
    "Import Interchange File..."
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("square.and.arrow.down")
  }

  public func help(centre: BookishHarness) -> String? {
    "Import records from a Bookish interchange JSON file."
  }

  public func perform(centre: BookishHarness) async throws {
    centre.requestInterchangeImport()
  }
}

/// Imports one of Bookish's bundled Delicious Library samples.
public struct ImportDeliciousLibrarySampleCommand: CommandWithUI {
  public typealias Centre = BookishHarness
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

  public func name(centre: BookishHarness) -> String {
    switch sample {
    case .small:
      "Small Sample"
    case .full:
      "Full Sample"
    }
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("books.vertical")
  }

  public func help(centre: BookishHarness) -> String? {
    "Import the bundled \(name(centre: centre)) Delicious Library XML export."
  }

  public func perform(centre: BookishHarness) async throws {
    await centre.importDeliciousLibrary(sample: sample)
  }
}

/// Requests a Delicious Library import through the view-owned file picker.
public struct ImportOtherDeliciousLibraryCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.import.delicious-library.other"

  public init() {
  }

  public func name(centre: BookishHarness) -> String {
    "Other…"
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("books.vertical")
  }

  public func help(centre: BookishHarness) -> String? {
    "Import records from another Delicious Library XML export."
  }

  public func perform(centre: BookishHarness) async throws {
    centre.requestDeliciousLibraryImport()
  }
}

/// Exports the materialised records as Bookish interchange JSON.
public struct ExportInterchangeCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.export.interchange"
  public var shortcut: CommandShortcut? { .init("e", modifiers: [.command, .shift]) }

  public init() {
  }

  public func availability(centre: BookishHarness) -> CommandAvailability {
    centre.navigation.recordIDs.isEmpty ? .disabled : .enabled
  }

  public func name(centre: BookishHarness) -> String {
    "Export Interchange File..."
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("square.and.arrow.up")
  }

  public func help(centre: BookishHarness) -> String? {
    "Export the current materialised records as Bookish interchange JSON."
  }

  public func perform(centre: BookishHarness) async throws {
    await centre.requestInterchangeExport()
  }
}

/// Removes all records and mutations from the local datastore.
public struct ResetDatastoreCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.reset"

  public init() {
  }

  public func name(centre: BookishHarness) -> String {
    "Reset Bookish Datastore"
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("trash")
  }

  public func help(centre: BookishHarness) -> String? {
    "Remove every record and mutation from the datastore."
  }

  public func confirmation(centre: BookishHarness) -> CommandConfirmation? {
    CommandConfirmation(
      title: "Reset Bookish Datastore?",
      cancel: "Cancel",
      message: "This removes every record and mutation from the datastore.",
      confirm: "Reset"
    )
  }

  public func perform(centre: BookishHarness) async throws {
    await centre.reset()
  }
}

/// Rebuilds the materialised record projection from stored mutations.
public struct RebuildRecordStoreCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.rebuild-record-store"

  /// Creates the record-store rebuild command.
  public init() {
  }

  public func name(centre: BookishHarness) -> String {
    "Rebuild Record Store"
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("arrow.clockwise")
  }

  public func help(centre: BookishHarness) -> String? {
    "Discard the materialised record store and rebuild it from stored mutations."
  }

  public func confirmation(centre: BookishHarness) -> CommandConfirmation? {
    CommandConfirmation(
      title: "Rebuild Record Store?",
      cancel: "Cancel",
      message: "This discards the materialised record store and rebuilds it from stored mutations.",
      confirm: "Rebuild"
    )
  }

  public func perform(centre: BookishHarness) async throws {
    await centre.rebuildRecordProjection()
  }
}

/// Marks the selected record as currently being read.
public struct MarkReadingCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.mark-reading"
  public var shortcut: CommandShortcut? { .init("r", modifiers: [.command, .shift]) }

  public init() {
  }

  public func availability(centre: BookishHarness) -> CommandAvailability {
    centre.navigation.selectedRecordID == nil ? .disabled : .enabled
  }

  public func name(centre: BookishHarness) -> String {
    "Mark Reading"
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("book")
  }

  public func help(centre: BookishHarness) -> String? {
    "Mark the selected record as currently being read."
  }

  public func perform(centre: BookishHarness) async throws {
    await centre.markReading()
  }
}

/// Marks the selected record as finished.
public struct MarkFinishedCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.mark-finished"
  public var shortcut: CommandShortcut? { .init("f", modifiers: [.command, .shift]) }

  public init() {
  }

  public func availability(centre: BookishHarness) -> CommandAvailability {
    centre.navigation.selectedRecordID == nil ? .disabled : .enabled
  }

  public func name(centre: BookishHarness) -> String {
    "Mark Finished"
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("checkmark.circle")
  }

  public func help(centre: BookishHarness) -> String? {
    "Mark the selected record as finished."
  }

  public func perform(centre: BookishHarness) async throws {
    await centre.markFinished()
  }
}

/// Applies a synthetic remote mutation to the selected record.
public struct SimulateRemoteMutationCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.simulate-remote-mutation"

  public init() {
  }

  public func availability(centre: BookishHarness) -> CommandAvailability {
    centre.navigation.selectedRecordID == nil ? .disabled : .enabled
  }

  public func name(centre: BookishHarness) -> String {
    "Simulate Remote Mutation"
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("arrow.triangle.2.circlepath")
  }

  public func help(centre: BookishHarness) -> String? {
    "Apply a synthetic remote mutation to the selected record."
  }

  public func perform(centre: BookishHarness) async throws {
    await centre.simulateRemoteUpdate()
  }
}

/// Selects the next record index in the datastore browser.
public struct SelectNextRecordIndexCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.navigation.next-index"
  public var shortcut: CommandShortcut? { .init(.rightArrow, modifiers: [.command, .option]) }

  public init() {
  }

  public func availability(centre: BookishHarness) -> CommandAvailability {
    centre.navigation.recordIndexIDs.count > 1 ? .enabled : .disabled
  }

  public func name(centre: BookishHarness) -> String {
    "Next Record Index"
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("sidebar.right")
  }

  public func help(centre: BookishHarness) -> String? {
    "Select the next record index in the datastore browser."
  }

  public func perform(centre: BookishHarness) async throws {
    await centre.selectNextRecordIndex()
  }
}

/// Selects the previous record index in the datastore browser.
public struct SelectPreviousRecordIndexCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  public let id = "datastore.navigation.previous-index"
  public var shortcut: CommandShortcut? { .init(.leftArrow, modifiers: [.command, .option]) }

  public init() {
  }

  public func availability(centre: BookishHarness) -> CommandAvailability {
    centre.navigation.recordIndexIDs.count > 1 ? .enabled : .disabled
  }

  public func name(centre: BookishHarness) -> String {
    "Previous Record Index"
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("sidebar.left")
  }

  public func help(centre: BookishHarness) -> String? {
    "Select the previous record index in the datastore browser."
  }

  public func perform(centre: BookishHarness) async throws {
    await centre.selectPreviousRecordIndex()
  }
}

/// Selects the next record in the active datastore browser index.
public struct SelectNextRecordCommand: CommandWithUI {
  public typealias Centre = BookishNavigationService
  public typealias ResultType = Void

  public let id = "datastore.navigation.next-record"
  public var shortcut: CommandShortcut? { .init(.downArrow, modifiers: [.command, .option]) }

  public init() {
  }

  public func availability(centre: BookishNavigationService) -> CommandAvailability {
    centre.selectedRecordIDs.count > 1 ? .enabled : .disabled
  }

  public func name(centre: BookishNavigationService) -> String {
    "Next Record"
  }

  public func icon(centre: BookishNavigationService) -> Icon {
    Icon("arrow.down")
  }

  public func help(centre: BookishNavigationService) -> String? {
    "Select the next record in the active datastore browser index."
  }

  public func perform(centre: BookishNavigationService) async throws {
    centre.selectNextRecord()
  }
}

/// Selects the previous record in the active datastore browser index.
public struct SelectPreviousRecordCommand: CommandWithUI {
  public typealias Centre = BookishNavigationService
  public typealias ResultType = Void

  public let id = "datastore.navigation.previous-record"
  public var shortcut: CommandShortcut? { .init(.upArrow, modifiers: [.command, .option]) }

  public init() {
  }

  public func availability(centre: BookishNavigationService) -> CommandAvailability {
    centre.selectedRecordIDs.count > 1 ? .enabled : .disabled
  }

  public func name(centre: BookishNavigationService) -> String {
    "Previous Record"
  }

  public func icon(centre: BookishNavigationService) -> Icon {
    Icon("arrow.up")
  }

  public func help(centre: BookishNavigationService) -> String? {
    "Select the previous record in the active datastore browser index."
  }

  public func perform(centre: BookishNavigationService) async throws {
    centre.selectPreviousRecord()
  }
}

/// Navigates directly to a materialised record in the datastore browser.
public struct NavigateToRecordCommand: CommandWithUI {
  public typealias Centre = BookishNavigationService
  public typealias ResultType = Void

  public let id: String
  private let recordID: BookishRecordID

  /// Creates a record navigation command for a specific target.
  public init(recordID: BookishRecordID) {
    self.id = "datastore.navigation.record.\(recordID.rawValue)"
    self.recordID = recordID
  }

  public func availability(centre: BookishNavigationService) -> CommandAvailability {
    centre.contains(recordID: recordID) ? .enabled : .disabled
  }

  public func name(centre: BookishNavigationService) -> String {
    "Go to Record"
  }

  public func icon(centre: BookishNavigationService) -> Icon {
    Icon("arrow.right.circle")
  }

  public func help(centre: BookishNavigationService) -> String? {
    "Navigate to the linked record."
  }

  public func perform(centre: BookishNavigationService) async throws {
    centre.select(recordID: recordID)
  }
}
