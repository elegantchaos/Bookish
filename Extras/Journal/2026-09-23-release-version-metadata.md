# Release Version Metadata

## Change

- Updated `Sources/Bookish/Resources/Info.plist` so
  `CFBundleShortVersionString` and `CFBundleVersion` use the `RT_VERSION` and
  `RT_BUILD` tokens injected by ReleaseTools during archive creation.

## Rationale

ReleaseTools enables Info.plist preprocessing and replaces literal
`RT_VERSION` and `RT_BUILD` occurrences when archiving. Using the raw tokens
keeps the archive metadata's marketing-version and build-number values
available to `rt submit`.

## Validation

- `plutil -lint Sources/Bookish/Resources/Info.plist` passed.
- `rt validate --target Bookish` was blocked before the build: SwiftPM manifest
  inspection cannot run its internal sandbox in this environment.
