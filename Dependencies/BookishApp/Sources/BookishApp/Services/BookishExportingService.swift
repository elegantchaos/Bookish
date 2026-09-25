// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCoding
import BookishDatastore
import BookishRecord
import Foundation

/// Produces interchange files from the records owned by a storage service.
@MainActor
public final class BookishExportingService {
  /// Encodes materialised Bookish records as interchange data.
  @MainActor
  public protocol API {
    /// Encodes every materialised record and associates the supplied record as the interchange root.
    func interchangeData(root: BookishRecordID?) async throws -> Data
  }

  /// The storage service supplying materialised records for export.
  private let storageService: BookishStorageService

  /// Creates an exporter that reads from the supplied storage service.
  public init(storageService: BookishStorageService) {
    self.storageService = storageService
  }
}

extension BookishExportingService: BookishExportingService.API {
  /// Encodes every materialised record and associates the supplied record as the interchange root.
  public func interchangeData(root: BookishRecordID?) async throws -> Data {
    let records = try await storageService.records(matching: RecordQuery(sort: [.kind, .id]))
    return try BookishInterchangeCodec().encode(
      BookishInterchangeFile(root: root, records: records))
  }
}
