// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord

extension BookishRecordValue {
  /// Formats a Bookish property value for display.
  var displayString: String {
    if let date = dateValue {
      return date.formatted(date: .abbreviated, time: .omitted)
    }

    if let url = urlValue {
      return url.absoluteString
    }

    return switch self {
    case .string(let value):
      value
    case .integer(let value):
      value.formatted()
    case .double(let value):
      value.formatted()
    case .bool(let value):
      value ? "Yes" : "No"
    case .record(let id):
      id.rawValue
    case .blob(let reference):
      reference.filename ?? reference.id
    case .list(let values):
      values.map(\.displayString).joined(separator: ", ")
    case .encoded(let value, _):
      value.keys.sorted().joined(separator: ", ")
    case .tombstone:
      "Tombstone"
    case .deletion:
      "Deleted"
    case .conflict(let values):
      values.map(\.displayString).joined(separator: " / ")
    }
  }
}
