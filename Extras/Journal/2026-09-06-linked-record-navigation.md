# Linked Record Navigation

Record-link navigation now defaults to appending the target identifier to the detail column's navigation path. This lets links open records that are not members of the active index while retaining the index selection and supporting standard back navigation.

`NavigateToRecordCommand.Mode.currentIndex` preserves the former selection-only behavior when callers require the target to be in the active index. The declared `.bestIndex` mode is intentionally unavailable until index ranking and switching are implemented.
