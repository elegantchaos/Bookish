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

  /// The stable identifier of the preferred value editor.
  public var editor: String?

  /// Whether the viewer remains visible when the record has no value for the property.
  public var alwaysShowViewer: Bool?

  /// Creates property presentation metadata.
  public init(
    icon: String? = nil,
    label: String? = nil,
    viewer: String? = nil,
    editor: String? = nil,
    alwaysShowViewer: Bool? = nil
  ) {
    self.icon = icon
    self.label = label
    self.viewer = viewer
    self.editor = editor
    self.alwaysShowViewer = alwaysShowViewer
  }
}
