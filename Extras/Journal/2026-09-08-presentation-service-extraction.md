# Presentation Service Extraction

`BookishPresentationService` now owns layout selection, compatible-layout filtering,
record-layout resolution, and cascading property-presentation resolution. It reads
configuration from `BookishStorageService` without owning datastore model state.

`BookishHarness` coordinates the navigation and presentation services but no longer
duplicates layout state or provides presentation-resolution wrappers. Browser views
and tests use the presentation service directly.

The platform-specific fallback in `RevealDatastoreFolderCommand` now uses the narrow
status-reporting provider required to report its unavailable state.

Validation: `rt validate --target BookishApp` and comprehensive `rt validate` passed.
