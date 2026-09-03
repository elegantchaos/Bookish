// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

/// Presentation metadata for one record property.
public struct BookishPropertyPresentation: Codable, Equatable, Sendable {
  /// The SF Symbol used for the property, when one is known.
  public var icon: String?

  /// The display label or localisation key for the property.
  public var label: String?

  /// The stable identifier of the preferred value viewer.
  public var viewer: String?

  /// Creates property presentation metadata.
  public init(icon: String? = nil, label: String? = nil, viewer: String? = nil) {
    self.icon = icon
    self.label = label
    self.viewer = viewer
  }
}
