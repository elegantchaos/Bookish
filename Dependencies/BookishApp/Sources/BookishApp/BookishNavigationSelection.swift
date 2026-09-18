// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord

/// Identifies the durable route selected in the Bookish sidebar.
public enum BookishNavigationSelection: Hashable, RawRepresentable, Sendable {
  /// Allows navigation to select its normal initial route.
  case automatic

  /// Displays a top-level workflow.
  case mainSection(BookishMainSection)

  /// Displays a library or debug record index.
  case recordIndex(BookishRecordID)

  /// Restores a navigation selection from its durable representation.
  public init?(rawValue: String) {
    if rawValue == "automatic" {
      self = .automatic
    } else if rawValue.hasPrefix("section:") {
      let sectionRawValue = String(rawValue.dropFirst("section:".count))
      guard let section = BookishMainSection(rawValue: sectionRawValue) else {
        return nil
      }
      self = .mainSection(section)
    } else if rawValue.hasPrefix("index:") {
      let recordIndexRawValue = String(rawValue.dropFirst("index:".count))
      self = .recordIndex(BookishRecordID(recordIndexRawValue))
    } else {
      return nil
    }
  }

  /// The durable representation used by application settings.
  public var rawValue: String {
    switch self {
    case .automatic:
      "automatic"
    case .mainSection(let section):
      "section:\(section.rawValue)"
    case .recordIndex(let recordIndexID):
      "index:\(recordIndexID.rawValue)"
    }
  }
}
