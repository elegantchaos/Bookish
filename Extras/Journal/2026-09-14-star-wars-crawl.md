# 2026-09-14 Star Wars Crawl

## Changes

- Replaced the original fixed-offset animation in `Dependencies/StarWarsView` with a timeline-driven, measured perspective crawl.
- The crawl uses one motion model for upward movement and scale, so text of any measured height starts below and finishes beyond the viewport.
- Added a static, scrollable reading presentation for Reduce Motion.
- Added a standard running preview and a `0.0 ... 1.0` scrubber preview that share the production crawl scene.
- Replaced an accidentally copied `BookishCoding` test source with focused Swift Testing coverage for crawl geometry and timing bounds.

## Validation

- `rt validate --target StarWarsView` passed the package build and all `StarWarsViewTests` after selecting the correct Xcode toolchain.
- Comprehensive `rt validate` passed formatting and lint, then began its generic iOS and macOS app builds. Those stages had not produced output or completed at the end of the session.
