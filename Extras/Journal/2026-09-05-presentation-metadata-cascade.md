# Presentation Metadata Cascade

Property metadata now resolves through an injected `PresentationResolver`. The current `CascadingPresentationResolver` uses layout-specific, kind-specific, then generic presentation records, allowing resolution policy to evolve independently from record views.

The presentation seed defines shared metadata for seed and configuration properties, plus book-specific metadata for all properties emitted by the Delicious importer.
