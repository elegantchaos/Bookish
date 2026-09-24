# Compact Record Title

## Change

- `BookishRecordView` now accepts `showsNavigationTitle`, defaulting to `true` so existing callers and macOS retain their navigation title.
- `BookishRecordIDDetail` passes `false` for compact iOS width. The record header remains visible, while the empty navigation title uses inline display to avoid a blank large-title area.

## Verification

- `agt format` passed with three existing lint warnings in unrelated files. Formatting changes outside this task were reverted.
- `rt validate` passed format, lint, and generic iOS and macOS workspace builds.
- A generic iOS Simulator build passed. A separate iPhone 18 Pro Simulator displayed one record title in the header, with Back and More still visible. The screenshot is in `.build/tmp/bookish-record-title-iphone.png`.
