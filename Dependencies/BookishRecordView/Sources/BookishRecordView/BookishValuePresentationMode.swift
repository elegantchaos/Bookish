// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

/// The interaction mode used to select value components and visible fields.
public enum BookishValuePresentationMode: Sendable {
  /// Displays only values present on the record.
  case viewing

  /// Displays every field supplied by the active layout so values can be added.
  case editing
}
