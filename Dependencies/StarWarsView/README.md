# StarWarsView

`StarWarsView` presents text as a cinematic perspective crawl on macOS and iOS.
It has no package dependencies beyond the system SwiftUI framework.

```swift
StarWarsView(text: introduction, duration: 40)
```

The view performs one crawl each time it appears. It derives the crawl position
from elapsed time, measures its text so that it can leave the viewport
regardless of length, and combines an upward translation, perspective tilt, and
shrinking scale to create the receding effect.

When Reduce Motion is enabled, it replaces the animation with an ordinary,
scrollable reading layout.

The source includes two SwiftUI previews: a running crawl and an interactive
scrubber with a `0.0 ... 1.0` slider for inspecting every animation phase.

Run the package tests from this directory with:

```sh
swift test
```
