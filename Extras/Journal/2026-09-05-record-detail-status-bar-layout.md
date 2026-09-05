# Record Detail and Window Layout

The global status bar is now a vertical sibling of the browser split view rather than a safe-area overlay. The record detail form receives the remaining layout height, so its final property row remains within its scrollable content instead of being covered by the status bar.

The primary application window now has the stable `bookish-main` scene identifier and explicitly uses automatic restoration. macOS can associate its saved frame with this scene across application launches.
