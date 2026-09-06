// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

/// Window identifiers used by Bookish app scenes.
public enum BookishWindow: String, Sendable {
  /// The primary Bookish browser window.
  case main = "bookish-main"

  /// The debug-only mutation history window.
  case mutationDebug = "bookish-mutation-debug"
}
