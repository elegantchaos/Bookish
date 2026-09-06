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
