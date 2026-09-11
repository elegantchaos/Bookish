// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import CommandsUI
import Icons

/// Updates the name filter applied to the active browser index.
public struct SetRecordNameFilterCommand<Centre: BookishNavigationProvider>: CommandWithUI {
  public typealias ResultType = Void

  public let id = "datastore.navigation.record-name-filter"
  private let filter: String

  /// Creates a command that applies a partial record-name filter.
  public init(filter: String) {
    self.filter = filter
  }

  public func availability(centre _: Centre) -> CommandAvailability {
    .enabled
  }

  public func name(centre _: Centre) -> String {
    "Filter Records by Name"
  }

  public func icon(centre _: Centre) -> Icon {
    Icon("magnifyingglass")
  }

  public func help(centre _: Centre) -> String? {
    "Filter the active record index by a partial record name."
  }

  public func perform(centre: Centre) async throws {
    try await centre.navigationService.setRecordNameFilter(filter)
  }
}
