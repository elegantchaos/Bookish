// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecognition
import BookishRecord

extension BookRecognitionCandidate {
  /// Builds the initial catalogue record for a recognised book.
  var bookRecord: BookishRecord {
    BookishRecord(
      kind: BookishRecordKind.book,
      properties: [BookishRecordKey.name: .string(title)]
    )
  }
}
