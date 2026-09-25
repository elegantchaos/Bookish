# 2026-09-25 UI State Service Split

The fourth service refactor pass removed `BookishUIStateService`. Each of its
responsibilities now has one owner with the nested `State`/`API`/`Provider`
shape from [Decision 0022](../Decisions/0022-service-state-api-and-provider-shape.md):

- `BookishBrowserService` owns debug-index visibility and browser refresh. It
  has no `State`, because no view observes its properties.
- `BookishImportingService` owns the whole import workflow. The earlier
  model-side importer and the review workflow were merged: the workflow was the
  importer's only consumer, and keeping two services for one concern duplicated
  ownership. Reading sources and applying plans remain internal methods, which
  the model-level tests call directly.
- `BookishExportingService` gained the export sheet state and the
  `hasExportableRecords`/`requestInterchangeExport` API.
- `BookishSettingsPresentationService` owns the iOS settings sheet.
- `BookishRecordCreationService` owns New-record creation. Its creation and
  indexing behaviour is unchanged.
- `BookishRecordActionsService` moved into `Services/` and depends on storage,
  the navigation API, and the browser API instead of the ad-hoc
  `BookishRecordActionStorage` and `BookishRecordActionState` protocols.

The central provider file is gone; each provider is nested in its service. The
navigation API gained `selectedRecordID` and `recordIDs` for collaborators.

Services that write records still call `BookishBrowserService.API.refresh()`,
which advances the coarse storage revision so record views reload. These calls,
and the revision itself, are marked `TEMPORARY` in the source. They go away with
[Fine-Grained Record Observation](2026-09-25-fine-grained-record-observation.md).

Tests now use `BookishEngine` as their harness, created through an internal
initializer that accepts isolated `UserDefaults`. `UIStateCommandCentre` was
removed. Record-action unit tests use real temporary storage in place of storage
and state fakes.

`BookishUIStateView` keeps its name for now; renaming is left to the folder and
contract audit in the final pass.
