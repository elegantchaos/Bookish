# 2026-09-11 Workflow Two-Column Layout

Scanning, Import, and Cleanup now use a two-column `NavigationSplitView`: the shared sidebar and a full-width workflow detail area. The library browser retains its three independent sidebar, index, and record-detail columns.

Switching between layouts follows `BookishNavigationService.selectedMainSection`, so the existing native sidebar selection and preserved library-index context remain unchanged.
