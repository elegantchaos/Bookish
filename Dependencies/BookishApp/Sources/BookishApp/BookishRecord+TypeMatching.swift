// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord

/// Adds advisory record-kind matching used by layouts and indexes.
extension BookishRecord {
  /// Returns whether this configuration record supports any requested kind.
  func matchesAnyType(in requestedTypes: [String]) -> Bool {
    let supportedTypes = strings(BookishRecordKey.types) ?? []
    guard !supportedTypes.isEmpty, !requestedTypes.isEmpty else {
      return true
    }

    return supportedTypes.contains(BookishRecordKey.allTypes)
      || requestedTypes.contains(BookishRecordKey.allTypes)
      || !Set(supportedTypes).isDisjoint(with: requestedTypes)
  }
}
