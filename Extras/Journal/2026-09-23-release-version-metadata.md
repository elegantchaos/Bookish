# Release Version Metadata

## Change

- Updated `Sources/Bookish/Resources/Info.plist` so
  `CFBundleShortVersionString` uses the `RT_VERSION` token injected by
  ReleaseTools during archive creation.

## Rationale

ReleaseTools enables Info.plist preprocessing and replaces literal
`RT_VERSION` occurrences when archiving. Using the raw token keeps the archive
metadata's marketing-version value available to `rt submit`.

## Validation

- `plutil -lint Sources/Bookish/Resources/Info.plist` passed.
- `rt validate --target Bookish` was blocked before the build: SwiftPM manifest
  inspection cannot run its internal sandbox in this environment.
