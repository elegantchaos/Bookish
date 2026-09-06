# Query Sections

Layouts can now contain record links in their ordered `fields` list. A link to a `querySection` record renders a query-backed section at that exact position; ordinary string field entries and `*` expansion continue to work as before.

`RecordQueryTemplate` keeps a concrete base query separate from typed host-record relationship bindings. Resolving a template against the displayed record yields an ordinary `RecordQuery`, which is then served by the datastore query service and its existing observable-result cache. The initial bindings support scalar record links and record links contained in lists.

`QuerySectionSeed.bookish.json` supplies Books sections for people, series, and publishers. New datastores receive the updated layouts. Existing datastores refresh metadata and query-section records without overwriting user-edited layouts.
