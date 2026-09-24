# iPhone Global Command Menu

## Change

- Added a compact-width More menu to the sidebar, record index, record detail, and workflow navigation bars. This exposes global actions where the iPhone has no menu bar.
- Reused the existing command buttons for interchange import/export and Delicious Library import. The small and full bundled examples appear when Advanced Mode is enabled.
- Added Advanced and Developer Mode switches to the menu so testing commands can be reached on iPhone. Reset Bookish Datastore appears in Developer Mode and uses the command's confirmation before execution.
- Kept command execution and availability in the existing command layer, consistent with [Decision 0013](../Decisions/0013-commands-as-application-action-abstraction.md).

## Verification

- `rt validate` passed format, lint, and generic iOS and macOS builds.
- A generic iOS Simulator build passed. The menu button was visible on a separate iPhone 18 Pro Simulator's record detail screen.
- Menu interaction and reset confirmation have not been exercised in the Simulator.
