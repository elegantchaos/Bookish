# Navigation, Environment, and Status Capabilities

Navigation commands now depend on `BookishRecordNavigationService`, which exposes only record navigation operations and availability. `BookishNavigationService` implements that capability, while command tests use a fake navigation service instead of the concrete browser service.

`BookishCommandCentre` is injected through a custom SwiftUI environment value by the application engine. Linked-record and layout views no longer receive the command centre through initializer chains. The command boundary remains optional outside the application shell, where controls that require it are unavailable.

`BookishStatusReporting` is a narrow status capability vended by `BookishCommandCentre`. Command failures and view-loading errors now report through the command-centre environment instead of calling `BookishHarness.report` directly. The harness remains the owner of observable status state.

## Validation

Each focused change passed `rt validate --target BookishApp` before its commit. The status-reporting change also passed comprehensive `rt validate`, including formatting, linting, and iOS and macOS workspace builds.
