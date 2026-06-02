// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import Foundation

/// A materialised-record Bookish interchange file.
public struct BookishInterchangeFile: Equatable, Sendable {
  /// The file format marker.
  public var format: BookishInterchangeFormat

  /// The schema used by this file.
  public var schema: BookishInterchangeSchema

  /// The root record for this file, when one is defined.
  public var root: BookishRecordID?

  /// The records contained in this file.
  public var records: [BookishRecord]

  /// Creates an interchange file.
  public init(
    format: BookishInterchangeFormat = .records,
    schema: BookishInterchangeSchema = .default,
    root: BookishRecordID? = nil,
    records: [BookishRecord]
  ) {
    self.format = format
    self.schema = schema
    self.root = root
    self.records = records
  }
}
