import BookishRecord
import Foundation

/// Compares a proposed import graph with a catalogue snapshot without reading storage.
public struct BookishImportReconciler: Sendable {
  public init() {}

  public func plan(imported: BookishImportResult, existing: [BookishRecord]) throws
    -> BookishImportPlan
  {
    let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
    var proposedByID: [BookishRecordID: BookishRecord] = [:]
    var entries: [BookishImportPlanEntry] = []

    for record in imported.records {
      if let previous = proposedByID[record.id] {
        guard previous == record else {
          throw BookishImportPlanError.duplicateProposedID(record.id)
        }
        continue
      }
      proposedByID[record.id] = record

      let match: BookishImportMatch
      if let current = existingByID[record.id] {
        if current == record || isRepeat(record, current: current, sourceID: imported.sourceID) {
          match = .skip
        } else {
          match = .review(candidates: [current.id], sameID: true)
        }
      } else {
        let candidates = existing.filter { isPossibleMatch(record, $0) }.map(\.id)
        match = candidates.isEmpty ? .create : .review(candidates: candidates, sameID: false)
      }
      entries.append(BookishImportPlanEntry(record: record, match: match))
    }

    if imported.sourceID != BookishInterchangeImporter.sourceID {
      let needed = Set(
        entries.filter { $0.match != .skip }
          .flatMap { $0.record.properties.values.flatMap(\.recordReferences) })
      entries.removeAll { entry in
        [BookishRecordKind.person, BookishRecordKind.organisation, BookishRecordKind.series]
          .contains(entry.record.kind) && !needed.contains(entry.id)
      }
    }

    return BookishImportPlan(
      sourceID: imported.sourceID, root: imported.root, entries: entries,
      existingSnapshot: existing, diagnostics: imported.diagnostics)
  }

  private func isRepeat(_ record: BookishRecord, current: BookishRecord, sourceID: String) -> Bool {
    guard sourceID != BookishInterchangeImporter.sourceID,
      record.kind == current.kind,
      record.kind != BookishRecordKind.list,
      record.string(BookishRecordKey.source) == sourceID,
      current.string(BookishRecordKey.source) == sourceID
    else { return false }
    guard let importedID = record.string(BookishRecordKey.importedID), !importedID.isEmpty else {
      return false
    }
    return importedID == current.string(BookishRecordKey.importedID)
  }

  private func isPossibleMatch(_ proposed: BookishRecord, _ current: BookishRecord) -> Bool {
    guard proposed.kind == current.kind else { return false }
    if proposed.kind == BookishRecordKind.book {
      if let asin = proposed.string(BookishRecordKey.asin), !asin.isEmpty {
        return current.string(BookishRecordKey.asin) == asin
      }
      if let isbn = proposed.string(BookishRecordKey.isbn), !isbn.isEmpty {
        return current.string(BookishRecordKey.isbn) == isbn
      }
      return false
    }
    guard
      [BookishRecordKind.person, BookishRecordKind.organisation, BookishRecordKind.series]
        .contains(proposed.kind),
      let name = proposed.string(BookishRecordKey.name),
      let otherName = current.string(BookishRecordKey.name)
    else { return false }
    return name.importMatchKey == otherName.importMatchKey
  }
}

extension String {
  fileprivate var importMatchKey: String {
    folding(
      options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX")
    )
    .split(whereSeparator: \.isWhitespace)
    .joined(separator: " ")
  }
}
