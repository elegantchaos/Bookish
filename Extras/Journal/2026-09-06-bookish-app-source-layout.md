# BookishApp Source Layout

BookishApp now keeps independent implementation types in files named after those types. `BookishEngine`'s application-shell conformance, environment injector, `BookishHarness` error type, record-kind matching extension, navigation command-centre conformance, command error, and window identifiers each have focused source files.

Cross-file implementation details use module-internal visibility rather than `private` or `fileprivate`, which preserves encapsulation while allowing the focused files to collaborate. All BookishApp Swift files now use the standard source header. The browser views document their state and responsibilities, and their asynchronous work is routed through named methods rather than embedded task closures.

SwiftUI previews were intentionally left unchanged for this pass.
