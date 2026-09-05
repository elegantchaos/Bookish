# Legacy Findings

This document summarises older Bookish projects that were reviewed after being
archived under `Extras/Legacy/`, plus the still-live OCR project at
`~/Developer/Projects/BookishScanning`. The goal is to preserve product and user
experience ideas worth carrying into the current Bookish iteration, not to
recommend copying the older implementation technologies.

## Reviewed Projects

- `Extras/Legacy/BookishLists/`: an older SwiftUI catalogue app with lists,
  import, lookup, barcode scanning, configurable fields, and book detail views.
- `Extras/Legacy/BookishScanner/`: an older UIKit scanner app focused on adding
  books by barcode or manual lookup, then reviewing candidates.
- `~/Developer/Projects/BookishScanning/`: a live OCR/spine recognition research
  project. This should stay separate from the legacy archive.
- `Extras/Legacy/BookishTemp/`: an older model package with books, people,
  roles, publishers, series, and detail-field specifications.
- `Extras/Legacy/BookishCore/`: an unused legacy interchange package, retained
  for reference only and not part of the current app.
- `Extras/Legacy/BookishCoreClient/`: an early SwiftPM scaffold with little
  product-specific behavior.

## Features To Adopt

### Add Books Flow

The older apps consistently treated adding books as a workflow rather than a
single form. Users could scan a barcode, enter an ISBN/EAN, or search by
title/author, then choose from candidate matches.

Adopt this as a first-class Bookish workflow:

- provide one Add Books entry point;
- support manual ISBN/title/author search from the same surface as scanning;
- show lookup progress and errors inline;
- stage candidate results before inserting records;
- avoid creating records until the user confirms a candidate.

Relevant legacy references:

- `Extras/Legacy/BookishScanner/Sources/BookishScanner/CaptureView/CaptureViewController.swift`
- `Extras/Legacy/BookishLists/Sources/BookishLists/Views/ScannerView.swift`
- `Extras/Legacy/BookishLists/Sources/BookishLists/Views/IndexMenuView.swift`

### Candidate Review

`BookishScanner` and `BookishLists` both produced lookup candidates containing
title, authors, publisher, published date, cover image URL, page count, ISBN, and
source service. The standalone scanner had the more complete candidate detail
presentation, including cover thumbnails and source labeling.

Adopt a candidate review model that preserves:

- source service;
- title and subtitle where available;
- authors and other contributors;
- publisher and publication date;
- ISBN/EAN/ASIN identifiers;
- page count and format when available;
- cover thumbnail URL;
- raw provider payload for debugging or future cleanup.

Relevant legacy references:

- `Extras/Legacy/BookishScanner/Sources/BookishScanner/CandidateView/CandidateViewController.swift`
- `Extras/Legacy/BookishScanner/Sources/BookishScanner/Lookup/GoogleLookupService.swift`
- `Extras/Legacy/BookishLists/Sources/BookishLists/Lookup/LookupCandidate.swift`
- `Extras/Legacy/BookishLists/Sources/BookishLists/Lookup/GoogleLookupService.swift`

### Scan History And Add Queue

`BookishScanner` persisted confirmed candidates in a history that could be
reordered and deleted. That idea is stronger than the exact old presentation.
For current Bookish, it suggests a reviewable add queue or recently-added view.

Adopt this as:

- a temporary queue for scanned or looked-up candidates before import;
- a recently added history after confirmation;
- a recovery surface when a scan/import flow is interrupted;
- a place to batch accept, reject, merge, or edit candidates.

Relevant legacy references:

- `Extras/Legacy/BookishScanner/Sources/BookishScanner/HistoryView/HistoryManager.swift`
- `Extras/Legacy/BookishScanner/Sources/BookishScanner/HistoryView/HistoryItemDataSource.swift`
- `Extras/Legacy/BookishScanner/Sources/BookishScanner/HistoryView/HistoryItem.swift`

### Lists And Groups

`BookishLists` exposed a catalogue structure with `All Books`, user-created
lists, nested groups, and list membership. Lists could have notes and could
contain books, while groups organised other lists.

Adopt the product concept, but express it through the current record graph:

- `All Books` as a durable built-in index;
- user-managed lists for wishlist, owned, loaned, favourites, imports, and
  reading history;
- optional nested list groups;
- explicit list detail screens with name, notes, contents, and actions;
- deletion/removal semantics that distinguish deleting a book from removing it
  from one list.

Relevant legacy references:

- `Extras/Legacy/BookishLists/Sources/BookishLists/Views/IndexView.swift`
- `Extras/Legacy/BookishLists/Sources/BookishLists/Views/ListView.swift`
- `Extras/Legacy/BookishLists/Sources/BookishLists/Views/AllBooksView.swift`
- `Extras/Legacy/BookishLists/Sources/BookishLists/CDList.swift`

### Per-List Field Layouts

`BookishLists` let each list define a field list, including field order and a
simple kind such as string or number. This maps well to the current data-view and
layout-record direction.

Adopt the user-facing behavior:

- let a list or view choose which fields are visible;
- let users reorder fields;
- allow field-specific display names and types;
- persist layouts as records rather than hard-coded view state;
- make the same book render differently in different contexts when useful.

Relevant legacy references:

- `Extras/Legacy/BookishLists/Sources/BookishLists/Views/FieldEditorView.swift`
- `Extras/Legacy/BookishLists/Sources/BookishLists/FieldList.swift`
- `Extras/Legacy/BookishLists/Sources/BookishLists/Field.swift`
- `Extras/Documentation/Data View Design.md`

### Book Detail Surface

The older book detail screen showed editable title, notes, cover art, configured
fields, and a raw-properties disclosure. The raw-properties concept is useful
while import and cleanup behavior are still evolving.

Adopt:

- a polished book detail view with title/subtitle, cover, notes, and primary
  metadata;
- links to related people, publishers, series, and lists;
- raw imported properties hidden behind an advanced/debug disclosure;
- a clear distinction between user-edited fields and imported source data.

Relevant legacy references:

- `Extras/Legacy/BookishLists/Sources/BookishLists/Views/BookView.swift`
- `Extras/Legacy/BookishTemp/BookishModel/Sources/BookishModel/DetailSpec.swift`

### Domain Vocabulary

`BookishTemp` has useful model vocabulary even though the implementation is old.
It includes books, people, roles, publishers, series, groups, identifiers,
publication dates, dimensions, page count, notes, images, and raw import data.

Use it as a source for canonical record kinds and field names:

- book fields: title/name, subtitle, notes, format, ISBN-10, ISBN-13, ASIN, EAN,
  Dewey, published date, added date, modified date, import date, dimensions,
  page count, cover image, raw import payload;
- linked records: people, roles, publisher, series;
- default contributor roles: Author, Editor, Illustrator.

Relevant legacy references:

- `Extras/Legacy/BookishTemp/BookishModel/Sources/BookishModel/Book.swift`
- `Extras/Legacy/BookishTemp/BookishModel/Sources/BookishModel/Person.swift`
- `Extras/Legacy/BookishTemp/BookishModel/Sources/BookishModel/Role.swift`
- `Extras/Legacy/BookishTemp/BookishModel/Sources/BookishModel/Series.swift`
- `Extras/Legacy/BookishTemp/BookishModel/Sources/BookishModel/Collection.xcdatamodeld/Document.xcdatamodel/contents`

### Photo And Spine Recognition

The live `BookishScanning` project is not legacy. It is a research track for
recognising books in ordinary shelf photos by using OCR, text orientation,
region proposals, edge-boundary signals, overlays, and ranked candidates.

Adopt the product direction gradually:

- keep barcode scanning as a near-term add path;
- treat shelf-photo OCR as a future bulk-add or verification workflow;
- return ranked candidates with provenance and uncertainty;
- match recognised text against the user's existing catalogue before relying on
  remote metadata lookup;
- keep diagnostic overlays and debug tools available for development, not as
  primary user-facing UI.

Useful live references:

- `~/Developer/Projects/BookishScanning/Extras/Documentation/Research Summary.md`
- `~/Developer/Projects/BookishScanning/Extras/Documentation/SPECIFICATION.md`
- `~/Developer/Projects/BookishScanning/Sources/BookishScanning/RecognitionPipeline.swift`
- `~/Developer/Projects/BookishScanning/Sources/BookishDebugApp/Core/Sources/Core/DebugBrowserView.swift`

## Adoption Priority

1. Build a modern Add Books workflow around lookup candidates and explicit
   confirmation.
2. Add candidate-to-record mapping that preserves source data, cover artwork,
   identifiers, and raw payloads.
3. Introduce user-facing lists, including `All Books`, user lists, and import
   review lists.
4. Promote current layout records into editable data views, borrowing the
   per-list field editor behavior from `BookishLists`.
5. Expand the domain vocabulary using `BookishTemp` as a reference for record
   kinds, relationship roles, and standard book fields.
6. Add a scan/add history or queue once lookup and candidate confirmation exist.
7. Integrate the live OCR project later as a bulk-add research feature, after
   the normal add and lookup workflow is stable.

## Notes On Non-Adoption

The older projects used CoreData, UIKit, early SwiftUI, and older package
layouts. Those choices should not drive the current implementation. The valuable
assets are the workflows, screens, vocabulary, and product decisions:

- users need fast book entry;
- candidates should be reviewed before insertion;
- lists and layouts are central to catalogue browsing;
- imported data should remain inspectable;
- scanning and OCR should feed the same candidate pipeline as manual lookup.
