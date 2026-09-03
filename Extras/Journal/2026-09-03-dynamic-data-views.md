# Dynamic Data Views

Updated `Extras/Documentation/Data View Design.md` to describe Bookish's record-driven user interface.

## Documented Behaviour

- Layouts and indexes are metadata records held in the same datastore as catalogue data.
- Index records contain an encoded query, display configuration, optional layout, and advisory record-type list.
- Layout records contain ordered fields, `*` expansion, and advisory record-type compatibility.
- The browser executes selected index queries through the observable record query service and filters layout choices by compatible types.

## Documented Design

- Generic, record-type, and layout property presentation metadata cascade into an effective description.
- `PropertyPresentation` has optional `icon`, `label`, and `viewer` members.
- Labels are strings that attempt localisation and fall back to their literal value.
- Viewer identifiers choose a SwiftUI component without constraining the stored record value.
- User-authored indexes will support record types, predicates, sort descriptors, default layouts, and result previews.
