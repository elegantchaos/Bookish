// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import CommandsUI
import Icons

/// Selects a top-level Bookish workflow.
public struct SelectMainSectionCommand<Centre: BookishNavigationProvider>: CommandWithUI {
  public typealias ResultType = Void

  public let id: String
  private let section: BookishMainSection

  /// Creates a command that selects a workflow.
  public init(section: BookishMainSection) {
    self.id = "datastore.navigation.main-section.\(section.rawValue)"
    self.section = section
  }

  public func availability(centre _: Centre) -> CommandAvailability {
    .enabled
  }

  public func name(centre _: Centre) -> String {
    section.title
  }

  public func icon(centre _: Centre) -> Icon {
    Icon(section.systemImage)
  }

  public func help(centre _: Centre) -> String? {
    "Show the \(section.title) workflow."
  }

  public func perform(centre: Centre) async throws {
    centre.navigationService.select(mainSection: section)
  }
}
