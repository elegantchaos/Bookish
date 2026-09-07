# Mode-Gated Controls

Advanced Mode now exposes the layout picker, bundled Delicious Library sample imports, and the local datastore-folder command. Developer Mode exposes synthetic remote mutations, projection rebuilding, destructive datastore reset, debug indexes, and mutation diagnostics.

The Bookish menu contains persistent Advanced Mode and Developer Mode toggles. Changing Developer Mode refreshes the browser index query so debug indexes appear or disappear immediately; the harness keeps its injected initial visibility for deterministic tests.

The mutation debug window remains a debug-build scene, but its content also requires Developer Mode so a window already open when the preference changes no longer exposes mutation history.

## Validation

`rt validate --target BookishApp` passed its build and BookishAppTests stages.
