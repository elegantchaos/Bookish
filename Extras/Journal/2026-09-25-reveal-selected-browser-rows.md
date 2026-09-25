# 2026-09-25 Reveal Selected Browser Rows

Record creation already selected a compatible library index and the new record
in navigation state. The sidebar and record list relied on `List` selection to
show those rows, which did not explicitly reveal offscreen selections.

Both lists now identify their rows for `ScrollViewReader` and scroll to the
selected row when it is present. The selection bindings still own the highlight;
scrolling only controls visibility. The creation integration test also checks
that the selected record belongs to the active index result.
