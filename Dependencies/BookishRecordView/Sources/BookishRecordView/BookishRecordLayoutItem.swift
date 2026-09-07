// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord

/// An ordered item declared by a record layout.
public enum BookishRecordLayoutItem: Equatable, Identifiable, Sendable {
  /// A materialised record property.
  case field(BookishRecordField)

  /// A link to a query-section configuration record.
  case section(BookishRecordID)

  /// The stable identity used when rendering layout items in SwiftUI.
  public var id: String {
    switch self {
    case .field(let field):
      "field.\(field.key)"

    case .section(let sectionID):
      "section.\(sectionID.rawValue)"
    }
  }
}
