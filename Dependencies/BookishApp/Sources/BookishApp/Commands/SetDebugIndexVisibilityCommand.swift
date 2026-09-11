// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import CommandsUI
import Icons

/// Updates whether debug-only browser indexes are visible.
public struct SetDebugIndexVisibilityCommand<Centre: BookishBrowserSettingsProvider>: CommandWithUI
{
  public typealias ResultType = Void

  public let id = "datastore.browser.debug-index-visibility"
  private let isVisible: Bool

  /// Creates a command that updates debug-index visibility.
  public init(isVisible: Bool) {
    self.isVisible = isVisible
  }

  public func name(centre _: Centre) -> String {
    "Set Debug Index Visibility"
  }

  public func icon(centre _: Centre) -> Icon {
    Icon("ladybug")
  }

  public func help(centre _: Centre) -> String? {
    "Show or hide debug-only record indexes."
  }

  public func perform(centre: Centre) async throws {
    await centre.browserSettingsService.setShowsDebugIndexes(isVisible)
  }
}
