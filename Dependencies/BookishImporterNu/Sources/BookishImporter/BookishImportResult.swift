// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import Foundation

/// The provider-neutral output from a Bookish import tool.
public struct BookishImportResult: Equatable, Sendable {
  /// The importer or provider that produced these records.
  public var sourceID: String

  /// The root record for this import, when one is defined.
  public var root: BookishRecordID?

  /// The normalised records produced by the importer.
  public var records: [BookishRecord]

  /// Non-fatal import diagnostics.
  public var diagnostics: [String]

  /// Creates an import result.
  public init(
    sourceID: String,
    root: BookishRecordID? = nil,
    records: [BookishRecord],
    diagnostics: [String] = []
  ) {
    self.sourceID = sourceID
    self.root = root
    self.records = records
    self.diagnostics = diagnostics
  }
}
