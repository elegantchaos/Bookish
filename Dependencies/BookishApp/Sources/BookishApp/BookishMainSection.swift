// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

/// Identifies a top-level Bookish workflow outside the record browser.
public enum BookishMainSection: String, CaseIterable, Hashable, Sendable {
  /// The workflow for scanning physical books into the catalogue using the camera.
  /// We either scan a barcode, or we attempt to recognise books from the scene, using
  /// image recognition and other AI techniques.
  case capture

  /// The workflow for importing catalogue data.
  case importing

  /// The workflow for reviewing and repairing catalogue data.
  case cleanup
}

extension BookishMainSection {
  /// The user-facing name for the workflow.
  var title: String {
    switch self {
    case .capture:
      "Capture"
    case .importing:
      "Import"
    case .cleanup:
      "Cleanup"
    }
  }

  /// The SF Symbol that represents the workflow.
  var systemImage: String {
    switch self {
    case .capture:
      "viewfinder"
    case .importing:
      "square.and.arrow.down"
    case .cleanup:
      "dishwasher"
    }
  }

  /// The explanatory copy for a workflow that is not implemented yet.
  var placeholderDescription: String {
    switch self {
    case .capture:
      "Scanning tools will appear here."
    case .importing:
      "Import tools will appear here."
    case .cleanup:
      "Cleanup tools will appear here."
    }
  }
}
