# Command Provider Service Extraction

Command tests now use a fake command centre and fake services for imports, datastore maintenance, record actions, browser-index selection, and navigation. The tests verify command behavior through each provider seam without constructing `BookishHarness`.

`BookishCommandCentre` now keeps its harness private and publishes only command-facing capability references. This prevents command callers from recovering the broad datastore coordinator through the command boundary.

Record-action orchestration moved to `BookishRecordActions`. The service applies reading, finished, and remote-update mutations through an internal `BookishRecordActionStore`, while `BookishHarness` retains datastore lifetime, browser refresh, and user-facing status ownership.

## Validation

`rt validate --target BookishApp` passed after each commit. A final comprehensive validation follows this journal update.
