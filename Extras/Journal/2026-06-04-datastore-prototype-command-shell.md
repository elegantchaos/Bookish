# Datastore Prototype Command Shell

## Context

The datastore prototype now uses the local `elegantchaos/Commands` package for menu and toolbar actions and the local `elegantchaos/Application` package for the app shell.

## Implementation Notes

- Added `DatastorePrototypeEngine` as the `Application.AppEngine` bridge for startup state and datastore loading.
- Moved prototype menu actions into `Commands.CommandWithUI` and `CommandsUI.ImporterCommand` models.
- Updated the prototype toolbar to render command-backed import, export, mark, and remote-mutation controls.
- Kept `DatastorePrototypeHarnessView` usable in previews by retaining opt-in direct loading while the app shell disables duplicate loading.
- Pointed local package manifests at local `Application`, `Commands`, `Icons`, and `Logger` dependencies so the workspace resolves a single package graph.

## Validation

- `swift test` in `Dependencies/DatastorePrototypeApp`.
- `xcodebuild -workspace Bookish.xcworkspace -scheme DatastorePrototype -destination 'platform=macOS' build`.
- `rt validate --target DatastorePrototype`.
- `rt validate` reached the broad iOS `Bookish` build and failed because the main app graph still mixes local Logger 2 with packages that declare older iOS deployment floors, including an external `Images` target.

## Follow-Up

- Consider modernizing older local Bookish package manifests to Swift 6.3 and macOS/iOS 26.0 together, rather than package-by-package during feature work.
- The legacy and prototype graphs now use separate cleanup packages: `BookishCleanup` remains on Logger 1.x for `BookishLegacy`, while `BookishImporterNu` depends on `BookishCleanupNu` for the newer Logger 2.x prototype graph.
- `BookishLegacy` no longer fails because of `BookishCleanup`, but its iOS build still fails because external `Images` declares iOS 12 while resolved Logger 1.x requires iOS 13.
- Added a File menu command to reveal the local prototype datastore folder in Finder.
- Changed the reset menu item to perform directly because confirmation alerts attached to menu command items do not reliably invoke the command.
- Shifted the prototype harness away from owning materialised record arrays. It now keeps record/layout IDs and resolves records through `RecordService`, which exposes predicate-backed ID queries for the JSON prototype store and future SwiftData mapping.
