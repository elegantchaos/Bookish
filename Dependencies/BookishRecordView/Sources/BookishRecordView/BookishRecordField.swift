// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord

/// A single display-ready record field.
public struct BookishRecordField: Equatable, Identifiable, Sendable {
  /// The datastore property key.
  public let key: String

  /// The display label derived from the property key.
  public let label: String

  /// The SF Symbol used to represent the property, when available.
  public let icon: String?

  /// The stable identifier of the preferred value viewer, when configured.
  public let viewer: String?

  /// The stable identifier of the preferred value editor, when configured.
  public let editor: String?

  /// The formatted property value.
  public let value: String

  /// The source record value, if the field exists on the record.
  public let rawValue: BookishRecordValue?

  /// Creates a display field.
  public init(
    key: String,
    label: String,
    icon: String? = nil,
    viewer: String? = nil,
    editor: String? = nil,
    value: String,
    rawValue: BookishRecordValue? = nil
  ) {
    self.key = key
    self.label = label
    self.icon = icon
    self.viewer = viewer
    self.editor = editor
    self.value = value
    self.rawValue = rawValue
  }

  /// The stable identity for SwiftUI lists.
  public var id: String {
    key
  }
}
