# Linked Record Presentation

Record-link fields resolve their target record before rendering. The link shows the target `name`, uses its `image` URL for the thumbnail when available, and otherwise falls back to the icon declared by the most specific available index type for the target kind.

`BookishRecordThumbnail` is now a reusable BookishRecordView component so record indexes and record links share the same asynchronous image and SF Symbol fallback behavior.
