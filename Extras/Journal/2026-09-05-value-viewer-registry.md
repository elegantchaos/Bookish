# Value Viewer Registry

`BookishPropertyPresentation` now has independent `viewer` and `editor` identifiers. Presentation resolution merges individual metadata members from generic through kind-specific and layout-specific records, so a more-specific label does not discard a less-specific viewer or editor.

`BookishValueViewerRegistry` selects a component for viewing or editing. The current record-detail path uses viewing mode and safely falls back to selectable text for unsupported identifiers or incompatible values. It provides native viewers for lists, property-presentation values, and record links; list entries are rendered recursively, so record-link lists navigate item by item.

The default presentation seed marks catalogue contributors as `record.linkList`, series as `record.link`, and other known list fields as `list`. The Delicious Library importer already emits authors, illustrators, and publishers as lists of record references. Importer coverage now protects that graph shape.

Editing mode is intentionally an API boundary only. Editors will request normal datastore mutations rather than bind directly to persistence.
