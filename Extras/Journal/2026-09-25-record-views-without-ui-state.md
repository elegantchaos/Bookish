# 2026-09-25 Record Views Without UI State

The third service refactor pass removed record views' use of
`BookishUIStateService` as a service locator. `BookishRecordIDDetail`,
`RecordLinkButton`, `RecordLayoutItemView`, `RecordLayoutSectionView`,
`RecordQuerySectionView`, `RecordIndexView`, and the debug mutation browser
previously reached storage and presentation through `harness.navigation` and
`harness.presentation`. They now read `BookishStorageService.State` and
`BookishPresentationService.State` from the environment and no longer pass a
harness down the view tree.

`BookishStorageService.State` exposes read-only record, query-section, and
mutation reads, plus the `revision` counter views use to key reload tasks. The
counter moved from UI state to storage because what it signals is that stored
records should be resolved again. It is still bumped at the end of
`refreshBrowser()`, so reload timing is unchanged; the browser-refresh owner
introduced in the next pass should decide whether storage mutations bump it
directly. `BookishPresentationService.State` gained `layout(for:recordIndex:)`
for record detail.

`BookishRecordIDCell` had no callers and was deleted rather than migrated.

Import review, export, and Settings views still observe `BookishUIStateService`,
and recognition still calls its `refreshBrowser()`. Both are for the split in
the next pass. This applies [Decision 0022](../Decisions/0022-service-state-api-and-provider-shape.md).
