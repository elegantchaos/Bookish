# 2026-09-14 Star Wars Crawl

## Changes

- Replaced the original fixed-offset animation in `Dependencies/StarWarsView` with a timeline-driven, measured perspective crawl.
- The crawl uses one motion model for upward movement, so text of any measured height starts below and finishes beyond the viewport.
- The crawl translates the text before its 3D rotation, allowing perspective to reduce text only as it travels away from the camera instead of uniformly scaling the complete block.
- Increased the perspective-plane tilt from 55 to 78 degrees to make the receding angle more pronounced.
- Tuned the plane from the implementation/original-film comparison: 78-degree tilt, standard-strength perspective, and a 380-point text-column cap prevent the near text from clipping and leave more depth toward the horizon.
- Centered the crawl plane in its viewport before applying the transform, so both loose and dense text expand symmetrically instead of clipping at the leading edge.
- Made the zero-progress state black by placing the entire text plane below the viewport and suppressing its initial rendered frame.
- Added scrubber-only controls for tilt, perspective strength, and maximum column width, starting at the public crawl's standard camera settings.
- Added the opt-in `.denseJustified` layout, backed by AppKit and UIKit's native paragraph engines, while retaining `.loose` as the default crawl typography.
- Added a static, scrollable reading presentation for Reduce Motion.
- Added a standard running preview and a `0.0 ... 1.0` scrubber preview that share the production crawl scene.
- Replaced an accidentally copied `BookishCoding` test source with focused Swift Testing coverage for crawl geometry and timing bounds.

## Validation

- `rt validate --target StarWarsView` passed the package build and all `StarWarsViewTests` after selecting the correct Xcode toolchain.
- Comprehensive `rt validate` passed formatting and lint, then began its generic iOS and macOS app builds. Those stages had not produced output or completed at the end of the session.
