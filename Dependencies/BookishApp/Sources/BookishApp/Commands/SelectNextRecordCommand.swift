//
//  File.swift
//  BookishApp
//
//  Created by Sam Deane on 06/09/2026.
//

import Foundation
import Commands
import CommandsUI
import Icons

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
