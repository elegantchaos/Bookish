# BookishCore Legacy Relocation

Moved the unused `BookishCore` package from `Dependencies/BookishCore` to `Extras/Legacy/BookishCore`. The current Bookish app neither imports nor declares a dependency on it.

The prior nested repository at that destination was a separate three-commit SwiftPM hello-world scaffold with no substantive BookishCore implementation, so it was replaced.
