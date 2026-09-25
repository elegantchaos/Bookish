# 2026-09-25 Contextual Toolbar and New Records

Removed the global import, export, status, debug, and layout controls from the
main toolbar. Index, workflow, and visible book detail views now contribute
commands suited to their context. On iOS, a Settings command opens the existing
settings view as a sheet.

Added New commands for Book, Person, Organisation, Series, and List. The New
menu exposes all five; an index toolbar uses its `newRecordTypes` property for
one direct action or a type menu. Creation persists a placeholder record,
navigates to a suitable index, clears the name filter, and selects the record.
The destination must also have a query that includes the new record; a more
restrictive current index falls back to another configured library index.
Existing seeded indexes acquire the new property on load while retaining their
other stored values. See [Decision 0021](../Decisions/0021-index-configured-record-creation.md).

Linked detail status commands now target the visible book rather than the
selected index row. The lookup workflow's Search action also uses a command.

`agt format` and `agt validate --fast` passed. Comprehensive `agt validate`
built macOS and iOS and passed Bookish's macOS tests, then stopped because the
generated BookishLookup scheme has no test action. The iOS tests and later
stages were not reached.
