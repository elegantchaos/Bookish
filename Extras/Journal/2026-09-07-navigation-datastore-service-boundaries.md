# Navigation and Datastore Service Boundaries

`BookishNavigation` now combines browser-index and record navigation. Its provider vends one `BookishNavigationService`, so index and record commands share the same narrow command capability.

`BookishDatastoreService` owns the loaded `BookishDatastore`. `BookishNavigationService` retains only browser route and selection state, and asks the datastore service to materialise the selected index query. It does not store or mutate `BookishDatastore` directly.

`BookishHarness` now delegates top-level index selection and selected-index query refresh to navigation. It still owns layout selection and presentation coordination; a narrow index-selection callback reconciles an incompatible explicit layout after navigation changes the active index. The harness retains read-only access to the datastore service while import, maintenance, and presentation responsibilities await their own extractions.

SwiftUI's browser-index list calls navigation directly and reports any navigation failure through the injected command centre's status capability. Provider-seam tests now use a single `BookishNavigation` test double for both index and record commands.

## Validation

`rt validate --target BookishApp` passed: the `BookishApp` target built and `BookishAppTests` passed.
