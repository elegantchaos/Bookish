# 2026-09-25 Menu Layout and Feature Mode

The File menu now holds only record and interchange actions. An Import submenu
in the standard import/export group, below the New menu's divider, holds
Interchange File, Kindle Library, and the Delicious Library submenu. Export
Interchange File follows in its own section.

Datastore maintenance moved to a new Debug menu, which SwiftUI places before
Window. Reveal Datastore Folder needs advanced mode; Rebuild Record Store and
Reset Bookish Datastore need development mode. The whole Debug menu disappears
in normal mode, since every item in it is gated.

Visibility is controlled by a single `BookishFeatureMode` enum with `normal`,
`advanced`, and `development` cases, stored under the `FeatureMode` setting
key. `showsAdvanced` is true for advanced and development; `showsDevelopment`
is true only for development. The Bookish menu and General settings share a
`BookishFeatureModePicker`.
