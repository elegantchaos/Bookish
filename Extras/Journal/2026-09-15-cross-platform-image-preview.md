# Cross-Platform Recognition Image Preview

## Changes

- Consolidated the recognition image previews into `BookRecognitionImagePreview` with explicit `compact` and `flexible` sizing policies.
- Compact previews use a cropped, fixed 128-by-128-point presentation for compact-width iPhone layouts.
- Flexible previews fit the full image in the available space with a 64-point minimum and 128-point ideal height, serving macOS and regular-width iPad layouts.
- Flexible previews align their fitted image content to the trailing edge of the available pane.
- Retained the macOS-only `VSplitView`; the preview policy is now selected by the shared horizontal size-class environment instead of a platform conditional.
- The preview decodes image data through cross-platform ImageIO and creates SwiftUI images from `CGImage`, preserving source orientation metadata without AppKit or UIKit conversion.
- Preview decoding now runs through a dedicated loader from a task, keeping ImageIO work out of SwiftUI `body` evaluation.

## Validation

- `rt validate --target BookishApp` passed the macOS `BookishApp` scheme build with Xcode warnings.
- `rt validate` passed formatting, linting, and `Bookish` builds for generic iOS and macOS destinations.
