# 2026-09-11 Import and Browser-Setting Commands

File-picker completion actions now dispatch `ImportSelectedInterchangeCommand`
and `ImportSelectedDeliciousLibraryCommand`, rather than calling import methods
from the root view. Both commands use the existing narrow import-presentation
capability.

Developer-mode changes now dispatch `SetDebugIndexVisibilityCommand` through a
new `BookishBrowserSettingsProvider`. `BookishUIStateService` owns that small
mutation capability and the engine vends it as an existential for commands.

Direct SwiftUI bindings remain direct mutations by deliberate policy. That
includes picker, toggle, and navigation-path bindings; a command-intercepting
binding wrapper remains a possible later design.
