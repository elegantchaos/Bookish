# 2026-09-11 Record Index Name Filter

The record browser now exposes a searchable name field in `RecordIndexView`.

The filter composes the selected index's stored `RecordQuery` with a new
`propertyStringContains` predicate rather than filtering the rendered rows.
The predicate uses `localizedStandardContains`, and the navigation service owns
the active filter so selected-record navigation and browser commands operate on
the visible query result.

`RecordPredicate` persists the new predicate shape with its existing stable
encoding. Tests cover localized partial matching, encoding round-tripping, and
the selected-index query composition.
