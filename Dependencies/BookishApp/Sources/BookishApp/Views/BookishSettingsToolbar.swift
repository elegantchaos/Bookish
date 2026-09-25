#if os(iOS)
  import SwiftUI

  /// Keeps Settings available from every visible iOS navigation column.
  struct BookishSettingsToolbar: ToolbarContent {
    /// Whether this toolbar belongs to the always-visible sidebar.
    var isSidebar = false

    /// Compact navigation shows only the active column's toolbar.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// The command boundary used by the settings action.
    @Environment(BookishCommander.self) private var commander

    /// The settings action in the navigation bar.
    var body: some ToolbarContent {
      if isSidebar || horizontalSizeClass == .compact {
        commander.toolbarItem(OpenSettingsCommand(), placement: .topBarTrailing)
      }
    }
  }
#endif
