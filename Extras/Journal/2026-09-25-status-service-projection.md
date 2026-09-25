# 2026-09-25 Status Service Projection

The first service refactor pass moved `BookishStatusService` to a nested
`State`/`API`/`Provider` shape. The service owns a stable observable `State`;
SwiftUI receives that state through the environment. Commands receive only the
status-reporting `API` through the command centre's narrow `Provider`.

Status reporting exposed a useful boundary case. A view can report a failure
encountered while loading or presenting its own content through
`State.report(error:)`. That presentation effect does not need an undoable
command. Domain actions remain command-driven. The service itself handles
command and collaborator reports through its API, and import progress updates
the same state instance.

The current design document describes the migrated status service. Other
services still expose their existing view surfaces and will be handled in later
passes. [Decision 0014](../Decisions/0014-narrow-command-providers-and-services.md)
established narrow command providers and anticipated a separate view surface;
the exact nested projection pattern is now drafted in
[Decision 0022](../Decisions/0022-service-state-api-and-provider-shape.md).
