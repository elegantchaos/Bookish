// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import Foundation

/// Describes a materialised-record request.
public struct RecordQuery: Codable, Equatable, Sendable {
  /// The predicate used to decide which records are included.
  public var predicate: RecordPredicate

  /// The ordered sort descriptors applied after filtering.
  public var sort: [RecordSortDescriptor]

  /// Creates a record query.
  public init(
    predicate: RecordPredicate = .all,
    sort: [RecordSortDescriptor] = [.id]
  ) {
    self.predicate = predicate
    self.sort = sort
  }

  /// Filters and sorts records using this query.
  public func apply(to records: [BookishRecord]) -> [BookishRecord] {
    let matchingRecords = records.filter { predicate.matches($0) }
    let descriptors = sort.isEmpty ? [.id] : sort

    return matchingRecords.sorted { lhs, rhs in
      for descriptor in descriptors {
        let comparison = descriptor.compare(lhs, rhs)
        if comparison != .orderedSame {
          return comparison == .orderedAscending
        }
      }

      return lhs.id.rawValue < rhs.id.rawValue
    }
  }
}
