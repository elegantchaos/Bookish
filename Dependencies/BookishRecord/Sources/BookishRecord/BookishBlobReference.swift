// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// References immutable out-of-line blob data used by a record property.
public struct BookishBlobReference: Codable, Equatable, Sendable {
  /// The stable blob identifier.
  public var id: String

  /// The blob media type, when known.
  public var mediaType: String?

  /// The blob byte count, when known.
  public var byteCount: Int?

  /// A checksum string, when known.
  public var checksum: String?

  /// The original filename, when useful for presentation or diagnostics.
  public var filename: String?

  /// Creates a blob reference.
  public init(
    id: String,
    mediaType: String? = nil,
    byteCount: Int? = nil,
    checksum: String? = nil,
    filename: String? = nil
  ) {
    self.id = id
    self.mediaType = mediaType
    self.byteCount = byteCount
    self.checksum = checksum
    self.filename = filename
  }
}
