import Commands
import CommandsUI
import Icons
import SwiftUI
import UniformTypeIdentifiers

#if canImport(AppKit)
  import AppKit
#endif

/// macOS menu commands for the datastore prototype.
public struct DatastorePrototypeCommands: Commands {
  private let harness: DatastorePrototypeHarness

  /// Creates commands bound to a prototype harness.
  public init(harness: DatastorePrototypeHarness) {
    self.harness = harness
  }

  public var body: some Commands {
    CommandGroup(after: .newItem) {
      harness.importer(ImportInterchangeCommand())
      harness.importer(ImportDeliciousLibraryCommand())

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
    }
  }
}

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
}

/// Imports records from a Bookish interchange JSON file.
public struct ImportInterchangeCommand: ImporterCommand {
  public typealias Centre = DatastorePrototypeHarness
  public typealias ResultType = Void

  public let id = "datastore.import.interchange"
  public var shortcut: CommandShortcut? { .init("i", modifiers: [.command, .shift]) }
  public var types: [UTType] { [.json] }
  public var allowsMultipleSelection: Bool { false }
  public var state: ImporterCommandURLState = .unknown

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
    switch state {
    case .chosen(let urls):
      guard let url = urls.first else {
        return
      }
      await centre.importInterchange(from: url)

    case .error(let error):
      centre.report(error: error)

    case .unknown:
      break
    }
  }
}

/// Imports records from a Delicious Library XML property-list file.
public struct ImportDeliciousLibraryCommand: ImporterCommand {
  public typealias Centre = DatastorePrototypeHarness
  public typealias ResultType = Void

  public let id = "datastore.import.delicious-library"
  public var types: [UTType] { [.xml] }
  public var allowsMultipleSelection: Bool { false }
  public var state: ImporterCommandURLState = .unknown

  public init() {
  }

  public func name(centre: DatastorePrototypeHarness) -> String {
    "Import Delicious Library File..."
  }

  public func icon(centre: DatastorePrototypeHarness) -> Icon {
    Icon("books.vertical")
  }

  public func help(centre: DatastorePrototypeHarness) -> String? {
    "Import records from a Delicious Library XML export."
  }

  public func perform(centre: DatastorePrototypeHarness) async throws {
    switch state {
    case .chosen(let urls):
      guard let url = urls.first else {
        return
      }
      await centre.importDeliciousLibrary(from: url)

    case .error(let error):
      centre.report(error: error)

    case .unknown:
      break
    }
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
    centre.recordIDs.isEmpty ? .disabled : .enabled
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
    centre.selectedRecordID == nil ? .disabled : .enabled
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
    centre.selectedRecordID == nil ? .disabled : .enabled
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
    centre.selectedRecordID == nil ? .disabled : .enabled
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
