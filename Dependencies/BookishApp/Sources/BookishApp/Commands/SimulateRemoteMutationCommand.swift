// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Commands
import CommandsUI
import Icons

/// Applies a synthetic remote mutation to the selected record.
public struct SimulateRemoteMutationCommand<Centre: BookishRecordActionsProvider>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "datastore.simulate-remote-mutation"

  public init() {
  }

  public func availability(centre: Centre) -> CommandAvailability {
    centre.recordActionService.hasSelectedRecord ? .enabled : .disabled
  }

  public func name(centre: Centre) -> String {
    "Simulate Remote Mutation"
  }

  public func icon(centre: Centre) -> Icon {
    Icon("arrow.triangle.2.circlepath")
  }

  public func help(centre: Centre) -> String? {
    "Apply a synthetic remote mutation to the selected record."
  }

  public func perform(centre: Centre) async throws {
    await centre.recordActionService.simulateRemoteUpdate()
  }
}
