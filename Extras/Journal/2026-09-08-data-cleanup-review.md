# 2026-09-08 Data Cleanup Review

Reviewed `BookishCleanup`, the Delicious Library importer, current record and
datastore services, browser navigation, and the FoundationModels SDK interface.

`BookishCleanup` currently repairs publisher duplication and a defined set of
series/title patterns during Delicious Library import only. The importer then
creates deterministic related-record IDs from exact names, so existing and
near-duplicate graph records remain outside its scope.

`Extras/Documentation/Data Cleanup.md` records the replacement direction: pure
analysis rules returning reviewable plans, a separate durable merge operation,
a top-level Data Cleanup route replacing the browser's Coming Soon placeholder,
and optional on-device Foundation Models assistance after deterministic candidate
generation. No production behavior changed in this review.
