# 2026-09-25 New Menu Availability

The macOS New menu items were permanently disabled. `NewRecordCommand` is
enabled when `BookishRecordCreationService.canCreate(_:)` holds: storage has
loaded, and a library index can show the new record. The menu is built before
the datastore loads, and `BookishStorageService.isLoaded` was a plain computed
property on a non-observable class. The short-circuited `&&` therefore read no
observable state, so SwiftUI recorded no dependency and never re-evaluated the
menu.

`isLoaded` now lives on `BookishStorageService.State`, updated whenever the
service's datastore changes. The index check already reads navigation's
observable state. Both checks are kept. A test uses `withObservationTracking`
to confirm that loading the engine invalidates the New command's availability
and enables it. Reverting to the unobserved property makes the test fail.

Command availability should read only observable state. Otherwise a menu or
control can evaluate it once and never update.

## Possible follow-up

The Commands package can report a command as running, through
`isRunning`, `recordStartedCommand`, and `recordFinishedCommand`, but
`BookishEngine` does not implement them. Implementing observable
running-command tracking in the engine would let New, and any other command,
disable itself while a previous invocation is still running.
