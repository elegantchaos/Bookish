# Book Metadata Lookup Scaffolding

## Decision

`Dependencies/BookishLookup` is a storage-neutral package for remote and local
book-metadata lookup providers. It deliberately does not depend on the app or
datastore, but does depend on `BookishRecord` for canonical candidate snapshots.

## Changes

- Added `BookLookupProvider` as the adapter boundary, with stable identity,
  display metadata, availability, and an asynchronous lookup operation.
- Added the actor-owned `BookLookupService`, which runs all supported providers
  and preserves successful candidates when another provider fails.
- Added provider-neutral candidates with bibliographic fields, provider
  provenance, source identifiers, cover URLs, and raw provider data.
- Ported the legacy Google Books request and response mapping to an injected,
  async `URLSession` implementation.
- Moved Google Books and OpenAI credential retrieval to the application-owned
  `BookishServiceConfiguration`. Lookup and capture packages now receive only
  explicit configured provider instances.
- Added `Scripts/store-google-books-api-key.sh`, which reads a key without
  terminal echo and updates the matching Keychain internet-password item.
- Added runtime provider replacement/removal to Lookup and Capture, allowing
  BookishApp to apply a credential change without restarting.
- Added an Open Library search provider with a bounded result set, optional
  identifying `User-Agent`, and deterministic request/mapping coverage. Its
  work-level candidates are explicitly not treated as confirmed editions.
- Added `FakeBookLookupProvider` for deterministic previews, demos, and tests.
- Kept self lookup out of this package until it can depend on an explicit
  read-only catalogue query protocol rather than a concrete datastore service.
- Added the temporary Lookup workflow between Capture and Import. It offers a
  query field, a provider picker, result rows, and provider-failure reporting
  without writing to the catalogue.
- Made `BookishLookup` depend on `BookishRecord`, using a stable provider/source
  identifier to construct each candidate's canonical book-record snapshot.

## Validation

- `swift test` in `Dependencies/BookishLookup` passed the fake-provider,
  provider-failure aggregation, provider reconfiguration, Google Books mapping,
  and Open Library mapping tests without live network access.
- `swift test` in `Dependencies/BookishCapture` passed its configured OpenAI
  request and recognizer-reconfiguration tests without credentials or network
  access.
- `swift test` in `Dependencies/BookishApp` passed 63 tests, including
  application configuration and runtime credential add/remove coverage.
- Comprehensive `rt validate` passed format and lint checks plus iOS and macOS
  builds after the application-owned configuration refactor.

## Later terminology update

- Renamed `BookishCapture` to `BookishRecognition`.
- Renamed recognition adapters, identifiers, registries, commands, and test
  fixtures from recognizer terminology to provider terminology.
- Added closed, string-backed provider-ID enums to lookup and recognition.
- `swift test` passed in `Dependencies/BookishRecognition`,
  `Dependencies/BookishLookup`, and `Dependencies/BookishApp`.
- `rt validate` passed formatting, linting, and iOS and macOS application builds.

## Documentation maintenance decision

- Recorded [decision 0019](../Decisions/0019-documentation-history-and-maintenance.md):
  journals preserve historical records, while core documentation describes the
  current system.

## Lookup settings update

- Moved lookup-provider selection from the temporary Lookup workflow to a new
  Lookup settings panel, alongside Capture settings.
- Google Books is always registered and displayed. It is disabled until the
  application supplies an API key, while lookup falls back to an available
  provider.
- Moved credential-storage helper scripts to `Extras/Scripts/`.
- `swift test` passed in `Dependencies/BookishLookup` and
  `Dependencies/BookishApp`; `rt validate` passed formatting, linting, and iOS
  and macOS application builds.

## Lookup settings layout correction

- Rendered provider availability as dedicated full-width settings rows, avoiding
  `Form` label-column layout interactions with multiline descriptions.
- Gave the preferences view a stable minimum size sized for the Lookup panel,
  so switching tabs does not resize the window.
