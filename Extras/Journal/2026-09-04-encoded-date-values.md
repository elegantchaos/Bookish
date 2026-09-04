# Encoded Date Values

## Summary

Removed the core `BookishRecordValue.date` case. Dates are now encoded
`BookishRecordDate` payloads tagged with the `date` kind hint.

## Coding

Added `BookishRecordCoding` as the single source of JSON encoder and decoder
configuration for encoded payloads. It uses ISO-8601 date coding, so dates
nested in other Codable values use the same representation as direct record
date payloads.

## Access and Querying

`BookishRecord.date(_:)` and `setDate(_:for:)` provide typed access. Record
sorting and record-view display decode those date payloads through the typed
accessor, preserving chronological sorting and formatted presentation.

`RecordQuery` and its `RecordSortDescriptor` values continue to be stored as a
single encoded payload. Their Codable date properties now inherit the shared
Bookish JSON date configuration.

## Validation

Focused Swift Testing suites passed for BookishRecord, BookishCoding,
BookishDatastore, BookishRecordView, and BookishImporterNu.
