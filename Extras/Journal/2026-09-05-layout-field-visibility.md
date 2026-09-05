# Layout Field Visibility

Record detail views now hide layout fields that have no corresponding record property while viewing. Editing mode retains every layout field, allowing an editor to add an absent property.

`BookishPropertyPresentation.alwaysShowViewer` overrides the viewing default for a specific property. The optional value cascades through generic, kind-specific, and layout-specific presentation records alongside the existing label, icon, viewer, and editor metadata.
