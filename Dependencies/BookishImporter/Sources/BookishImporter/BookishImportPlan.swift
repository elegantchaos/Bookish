import BookishRecord
import Foundation

/// A user's resolution for one proposed record that needs review.
public enum BookishImportChoice: Equatable, Hashable, Sendable {
  case create
  case keepExisting
  case useExisting(BookishRecordID)
  case replaceExisting
}

/// Why a proposed record will be created, skipped, or reviewed.
public enum BookishImportMatch: Equatable, Sendable {
  case create
  case skip
  case review(candidates: [BookishRecordID], sameID: Bool)
}

/// One proposed record and its relationship to the current catalogue.
public struct BookishImportPlanEntry: Equatable, Identifiable, Sendable {
  public let record: BookishRecord
  public let match: BookishImportMatch

  public var id: BookishRecordID { record.id }

  public init(record: BookishRecord, match: BookishImportMatch) {
    self.record = record
    self.match = match
  }
}

/// Records and root identity to persist after review and graph remapping.
public struct BookishImportResolution: Equatable, Sendable {
  public let records: [BookishRecord]
  public let root: BookishRecordID?

  public init(records: [BookishRecord], root: BookishRecordID?) {
    self.records = records
    self.root = root
  }
}

/// Errors raised when an import plan cannot be built or resolved safely.
public enum BookishImportPlanError: Error, Equatable, LocalizedError {
  case duplicateProposedID(BookishRecordID)
  case unresolved(BookishRecordID)
  case invalidChoice(BookishRecordID)

  public var errorDescription: String? {
    switch self {
    case .duplicateProposedID(let id): "The import contains conflicting records for \(id)."
    case .unresolved: "Review every possible match before importing."
    case .invalidChoice: "An import choice no longer matches the proposed records."
    }
  }
}

/// A storage-neutral proposal for adding one imported record graph to a catalogue.
public struct BookishImportPlan: Equatable, Sendable {
  public let sourceID: String
  public let root: BookishRecordID?
  public let entries: [BookishImportPlanEntry]
  public let existingSnapshot: [BookishRecord]
  public let diagnostics: [String]

  public var reviewEntries: [BookishImportPlanEntry] {
    entries.filter {
      if case .review = $0.match { return true }
      return false
    }
  }

  public var newCount: Int { entries.filter { $0.match == .create }.count }
  public var skippedCount: Int { entries.filter { $0.match == .skip }.count }

  public init(
    sourceID: String, root: BookishRecordID?, entries: [BookishImportPlanEntry],
    existingSnapshot: [BookishRecord], diagnostics: [String] = []
  ) {
    self.sourceID = sourceID
    self.root = root
    self.entries = entries
    self.existingSnapshot = existingSnapshot
    self.diagnostics = diagnostics
  }

  /// Resolves all review items and rewrites links to reused catalogue records.
  public func resolve(choices: [BookishRecordID: BookishImportChoice]) throws
    -> BookishImportResolution
  {
    var targets: [BookishRecordID: BookishRecordID] = [:]
    var writes: [BookishRecord] = []

    for entry in entries {
      switch entry.match {
      case .create:
        targets[entry.id] = entry.id
        writes.append(entry.record)

      case .skip:
        targets[entry.id] = entry.id

      case .review(let candidates, let sameID):
        guard let choice = choices[entry.id] else {
          throw BookishImportPlanError.unresolved(entry.id)
        }
        switch choice {
        case .create where !sameID:
          targets[entry.id] = entry.id
          writes.append(entry.record)
        case .keepExisting where sameID:
          targets[entry.id] = entry.id
        case .replaceExisting where sameID:
          targets[entry.id] = entry.id
          writes.append(entry.record)
        case .useExisting(let id) where !sameID && candidates.contains(id):
          targets[entry.id] = id
        default:
          throw BookishImportPlanError.invalidChoice(entry.id)
        }
      }
    }

    writes = writes.map { record in
      var record = record
      record.properties = record.properties.mapValues { $0.remappingRecords(using: targets) }
      return record
    }

    // External importers create person/organisation/series records as book relationships.
    // When a book is skipped or reused, discard related candidates no surviving write uses.
    if sourceID != BookishInterchangeImporter.sourceID {
      let referenced = Set(writes.flatMap { $0.properties.values.flatMap(\.recordReferences) })
      writes.removeAll { record in
        [BookishRecordKind.person, BookishRecordKind.organisation, BookishRecordKind.series]
          .contains(record.kind)
          && record.string(BookishRecordKey.source) == sourceID
          && !referenced.contains(record.id)
      }
    }

    return BookishImportResolution(records: writes, root: root.flatMap { targets[$0] ?? $0 })
  }
}

extension BookishRecordValue {
  fileprivate func remappingRecords(using targets: [BookishRecordID: BookishRecordID]) -> Self {
    switch self {
    case .record(let id): .record(targets[id] ?? id)
    case .list(let values): .list(values.map { $0.remappingRecords(using: targets) })
    case .conflict(let values): .conflict(values.map { $0.remappingRecords(using: targets) })
    default: self
    }
  }

  var recordReferences: [BookishRecordID] {
    switch self {
    case .record(let id): [id]
    case .list(let values), .conflict(let values): values.flatMap(\.recordReferences)
    default: []
    }
  }
}
