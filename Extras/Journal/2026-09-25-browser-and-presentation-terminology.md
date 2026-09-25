# 2026-09-25 Browser and Presentation Terminology

The documentation used "data view" as a catch-all for the record-configured
user interface. It is replaced by the terms the code already uses:

- **Presentation**: how one record looks. This covers presentation records,
  property metadata, layouts, query sections, and viewers, implemented by
  `BookishPresentationService` and `BookishRecordView`.
- **Browser**: how records are found and reached. This covers indexes, their
  query results, selection, and the linked-record path, implemented by
  `BookishNavigationService` and `BookishBrowserService`.
- **Configuration records**: the index, layout, presentation, metadata, and
  query-section records that configure both halves. The storage seeding code
  already calls them configuration.

`Data View Design.md` became `Browser and Presentation Design.md`, restructured
around configuration records, presentation, and the browser. The catalogue
model, specification, legacy findings, datastore implementation notes, and
README use the new terms; the specification's "description records" became
configuration records too. Decision 0004 was retitled "Configure the browser
and presentation with configuration records", a terminology change that leaves
its meaning intact; its filename is unchanged. Earlier journal entries keep
the old term as history.

`BookishBrowserService` owns only debug-index visibility and the temporary
refresh, while the browser's route lives in `BookishNavigationService`. Once
[Fine-Grained Record Observation](2026-09-25-fine-grained-record-observation.md)
removes the refresh, folding the remaining browser service into navigation is
worth considering.
