# Command Centre Provider Refactor

`BookishEngine` owns the single application command boundary, `BookishCommandCentre`. Menus, toolbar actions, and linked-record navigation now invoke commands through that boundary; the engine remains responsible only for application lifecycle and root-view construction.

Commands are generic over narrow providers for imports, datastore maintenance, record actions, browser-index selection, or record navigation. The command centre vends those focused capabilities while `BookishHarness` continues to implement the currently cohesive datastore work. This removes the former broad `BookishHarnessProvider` without adding another coordinator.

`BookishHarness` and `BookishNavigationService` no longer conform directly to `CommandCentre`. Command failures are reported by `BookishCommandCentre` through the harness status surface. Swift Testing verifies the vended service wiring and the diagnostic command's status reporting.

## Validation

Each migration step passed `rt validate --target BookishApp`. The final `rt validate` passed iOS and macOS workspace builds; its format and lint stages were skipped because there were no Swift files to process.

## Related Decisions

- [0001: Use BookishEngine as the command boundary](../Decisions/0001-engine-command-boundary.md)
- [0013: Use Commands as the application action abstraction](../Decisions/0013-commands-as-application-action-abstraction.md)
- [0014: Structure command capabilities around narrow service providers](../Decisions/0014-narrow-command-providers-and-services.md)
