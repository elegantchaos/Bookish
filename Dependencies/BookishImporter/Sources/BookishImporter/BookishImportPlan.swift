import BookishRecord
import Foundation

/// How the user wants one proposed record handled.
public enum BookishImportChoice: Equatable, Hashable, Sendable {
  /// Adds the imported record.
  case create
  /// Leaves the imported record out, removing links to it from the records that are added.
  case skip
  /// Keeps the catalogue record that shares the imported record's identifier.
  case keepExisting
  /// Links to a matching catalogue record instead of adding the imported one.
  case useExisting(BookishRecordID)
  /// Overwrites the catalogue record that shares the imported record's identifier.
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

  /// The choices that are valid for this record, in menu order.
  public var availableChoices: [BookishImportChoice] {
    switch match {
    case .create: [.create, .skip]
    case .skip: []
    case .review(_, sameID: true): [.keepExisting, .replaceExisting]
    case .review(let candidates, sameID: false):
      candidates.sorted { $0.rawValue < $1.rawValue }.map { .useExisting($0) } + [.create, .skip]
    }
  }
}

/// How an applied import treated one catalogue record.
public enum BookishImportTreatment: CaseIterable, Sendable {
  /// The imported record was added.
  case added
  /// The imported record overwrote the existing record with the same identifier.
  case replaced
  /// The existing record with the same identifier was kept.
  case kept
  /// An existing record was linked in place of a matching imported record.
  case matched

  /// The audit-list property that links the records given this treatment.
  public var auditKey: String {
    switch self {
    case .added: BookishRecordKey.importAdded
    case .replaced: BookishRecordKey.importReplaced
    case .kept: BookishRecordKey.importKept
    case .matched: BookishRecordKey.importMatched
    }
  }
}

/// Records and root identity to persist after review and graph remapping.
public struct BookishImportResolution: Equatable, Sendable {
  public let records: [BookishRecord]
  public let root: BookishRecordID?

  /// The catalogue records the import touched, in plan order, grouped by treatment.
  /// Skipped records are not included.
  public let treatments: [BookishImportTreatment: [BookishRecordID]]

  public init(
    records: [BookishRecord], root: BookishRecordID?,
    treatments: [BookishImportTreatment: [BookishRecordID]] = [:]
  ) {
    self.records = records
    self.root = root
    self.treatments = treatments
  }

  /// A list recording how the import treated each record, or nil when it touched none.
  public func auditList(id: BookishRecordID, name: String, sourceID: String, date: Date) throws
    -> BookishRecord?
  {
    guard treatments.values.contains(where: { !$0.isEmpty }) else { return nil }
    var properties: [String: BookishRecordValue] = [
      BookishRecordKey.name: .string(name),
      BookishRecordKey.source: .string(sourceID),
      BookishRecordKey.importDate: try BookishRecordValue(date: date),
    ]
    for (treatment, ids) in treatments where !ids.isEmpty {
      properties[treatment.auditKey] = .list(ids.map { .record($0) })
    }
    return BookishRecord(id: id, kind: BookishRecordKind.list, properties: properties)
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

  /// Records with no catalogue counterpart, which are added unless the user skips them.
  public var newEntries: [BookishImportPlanEntry] { entries.filter { $0.match == .create } }

  public var newCount: Int { newEntries.count }
  public var skippedCount: Int { entries.filter { $0.match == .skip }.count }

  /// Initial choices: add every new record, and prefer existing records for possible matches.
  public var defaultChoices: [BookishRecordID: BookishImportChoice] {
    choices(for: Set(newEntries.map(\.id)), setting: .create)
      .merging(choices(for: Set(reviewEntries.map(\.id)), preferring: .existing)) { _, new in new }
  }

  /// Sets one choice for the selected records that allow it, suitable for a bulk action.
  public func choices(for selectedIDs: Set<BookishRecordID>, setting choice: BookishImportChoice)
    -> [BookishRecordID: BookishImportChoice]
  {
    Dictionary(
      uniqueKeysWithValues: entries.compactMap { entry in
        selectedIDs.contains(entry.id) && entry.availableChoices.contains(choice)
          ? (entry.id, choice) : nil
      })
  }

  /// Choices for selected review records, suitable for a bulk action.
  public func choices(
    for selectedIDs: Set<BookishRecordID>, preferring preference: BookishImportPreference
  ) -> [BookishRecordID: BookishImportChoice] {
    Dictionary(
      uniqueKeysWithValues: reviewEntries.compactMap { entry in
        guard selectedIDs.contains(entry.id),
          case .review(let candidates, let sameID) = entry.match
        else { return nil }
        let choice: BookishImportChoice
        switch preference {
        case .existing:
          if sameID {
            choice = .keepExisting
          } else if let first = candidates.min(by: { $0.rawValue < $1.rawValue }) {
            choice = .useExisting(first)
          } else {
            return nil
          }
        case .imported:
          choice = sameID ? .replaceExisting : .create
        }
        return (entry.id, choice)
      })
  }

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
  ///
  /// New records without a choice are added. Skipped records are left out, and links to them
  /// are removed from the records that are written.
  public func resolve(choices: [BookishRecordID: BookishImportChoice]) throws
    -> BookishImportResolution
  {
    var targets: [BookishRecordID: BookishRecordID] = [:]
    var omitted: Set<BookishRecordID> = []
    var writes: [BookishRecord] = []
    var treated: [(BookishImportTreatment, BookishRecordID)] = []

    for entry in entries {
      if entry.match == .skip {
        targets[entry.id] = entry.id
        continue
      }
      guard let choice = choices[entry.id] ?? (entry.match == .create ? .create : nil) else {
        throw BookishImportPlanError.unresolved(entry.id)
      }
      guard entry.availableChoices.contains(choice) else {
        throw BookishImportPlanError.invalidChoice(entry.id)
      }
      switch choice {
      case .create:
        targets[entry.id] = entry.id
        writes.append(entry.record)
        treated.append((.added, entry.id))
      case .replaceExisting:
        targets[entry.id] = entry.id
        writes.append(entry.record)
        treated.append((.replaced, entry.id))
      case .keepExisting:
        targets[entry.id] = entry.id
        treated.append((.kept, entry.id))
      case .useExisting(let id):
        targets[entry.id] = id
        treated.append((.matched, id))
      case .skip:
        omitted.insert(entry.id)
      }
    }

    writes = writes.map { record in
      var record = record
      record.properties = record.properties.compactMapValues {
        $0.remappingRecords(using: targets, omitting: omitted)
      }
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

    // Pruned candidates were never written, so they are not part of the audit.
    let written = Set(writes.map(\.id))
    var treatments: [BookishImportTreatment: [BookishRecordID]] = [:]
    var listed: Set<BookishRecordID> = []
    for (treatment, id) in treated
    where (treatment == .kept || treatment == .matched || written.contains(id))
      && listed.insert(id).inserted
    {
      treatments[treatment, default: []].append(id)
    }

    return BookishImportResolution(
      records: writes,
      root: root.flatMap { omitted.contains($0) ? nil : targets[$0] ?? $0 },
      treatments: treatments)
  }
}

extension BookishRecordValue {
  /// Points links at their resolved targets, returning nil for a link to an omitted record.
  fileprivate func remappingRecords(
    using targets: [BookishRecordID: BookishRecordID], omitting omitted: Set<BookishRecordID>
  ) -> Self? {
    switch self {
    case .record(let id):
      omitted.contains(id) ? nil : .record(targets[id] ?? id)
    case .list(let values):
      .list(values.compactMap { $0.remappingRecords(using: targets, omitting: omitted) })
    case .conflict(let values):
      .conflict(values.compactMap { $0.remappingRecords(using: targets, omitting: omitted) })
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
