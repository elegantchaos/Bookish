# Legacy Feature Inventory

Reviewed older Bookish projects that were moved under `Extras/Legacy/`, while
treating `~/Developer/Projects/BookishScanning` as a live OCR research project.

The main output is `Extras/Documentation/Legacy Findings.md`. It records which
legacy folders were inspected and identifies product ideas worth carrying into
the current iteration: Add Books, candidate review, scan history, user-managed
lists, per-list layouts, richer domain vocabulary, and eventual shelf-photo OCR
integration.

The implementation takeaway is to borrow workflows and vocabulary, not older
technology choices. The current app should keep using the modern record graph,
importer, and SwiftUI direction while treating the old projects as product
reference material.
