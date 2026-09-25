import BookishRecord
import Foundation
import Testing

@testable import BookishImporter

struct BookishImportReconcilerTests {
  @Test
  func reusesExistingPersonAndRewritesBookLink() throws {
    let proposedAuthor = record(
      "kindle-person-raw", kind: BookishRecordKind.person, name: "Ada Sol",
      source: KindleLibraryImporter.sourceID)
    let existingAuthor = record("manual-author", kind: BookishRecordKind.person, name: "Ada Sol")
    let book = BookishRecord(
      id: BookishRecordID("kindle-book-B000000001"), kind: BookishRecordKind.book,
      properties: [
        BookishRecordKey.name: .string("The Glass Orbit"),
        BookishRecordKey.asin: .string("B000000001"),
        BookishRecordKey.source: .string(KindleLibraryImporter.sourceID),
        BookishRecordKey.authors: .list([.record(proposedAuthor.id)]),
      ])
    let imported = BookishImportResult(
      sourceID: KindleLibraryImporter.sourceID, records: [proposedAuthor, book])

    let plan = try BookishImportReconciler().plan(imported: imported, existing: [existingAuthor])
    #expect(plan.reviewEntries.count == 1)
    let resolved = try plan.resolve(choices: [proposedAuthor.id: .useExisting(existingAuthor.id)])

    #expect(resolved.records.count == 1)
    #expect(resolved.records.first?.list(BookishRecordKey.authors) == [.record(existingAuthor.id)])
    #expect(
      resolved.records.first?.string(BookishRecordKey.source) == KindleLibraryImporter.sourceID)
  }

  @Test
  func repeatImportSkipsBookAndItsUnusedAuthor() throws {
    let author = record(
      "kindle-person-raw", kind: BookishRecordKind.person, name: "Ada Sol",
      source: KindleLibraryImporter.sourceID)
    let book = BookishRecord(
      id: BookishRecordID("kindle-book-B000000001"), kind: BookishRecordKind.book,
      properties: [
        BookishRecordKey.name: .string("New title from source"),
        BookishRecordKey.source: .string(KindleLibraryImporter.sourceID),
        BookishRecordKey.importedID: .string("B000000001"),
        BookishRecordKey.authors: .list([.record(author.id)]),
      ])
    let existing = BookishRecord(
      id: book.id, kind: BookishRecordKind.book,
      properties: [
        BookishRecordKey.name: .string("My edited title"),
        BookishRecordKey.source: .string(KindleLibraryImporter.sourceID),
        BookishRecordKey.importedID: .string("B000000001"),
      ])
    let imported = BookishImportResult(
      sourceID: KindleLibraryImporter.sourceID, records: [author, book])

    let plan = try BookishImportReconciler().plan(imported: imported, existing: [existing])
    let resolved = try plan.resolve(choices: [:])

    #expect(plan.reviewEntries.isEmpty)
    #expect(resolved.records.isEmpty)
  }

  @Test
  func repeatedBookDoesNotAskAgainAboutAnExistingManualAuthor() throws {
    let author = record(
      "kindle-person-raw", kind: BookishRecordKind.person, name: "Ada Sol",
      source: KindleLibraryImporter.sourceID)
    let book = BookishRecord(
      id: BookishRecordID("kindle-book-B000000001"), kind: BookishRecordKind.book,
      properties: [
        BookishRecordKey.name: .string("The Glass Orbit"),
        BookishRecordKey.source: .string(KindleLibraryImporter.sourceID),
        BookishRecordKey.importedID: .string("B000000001"),
        BookishRecordKey.authors: .list([.record(author.id)]),
      ])
    let manualAuthor = record("manual-author", kind: BookishRecordKind.person, name: "Ada Sol")
    let plan = try BookishImportReconciler().plan(
      imported: BookishImportResult(
        sourceID: KindleLibraryImporter.sourceID, records: [author, book]),
      existing: [manualAuthor, book])

    #expect(plan.reviewEntries.isEmpty)
    #expect(try plan.resolve(choices: [:]).records.isEmpty)
  }

  @Test
  func manuallyEnteredBookWithSameASINNeedsAChoice() throws {
    let proposed = BookishRecord(
      id: BookishRecordID("kindle-book-B000000001"), kind: BookishRecordKind.book,
      properties: [
        BookishRecordKey.name: .string("The Glass Orbit"),
        BookishRecordKey.asin: .string("B000000001"),
        BookishRecordKey.source: .string(KindleLibraryImporter.sourceID),
      ])
    let existing = BookishRecord(
      id: BookishRecordID("manual-book"), kind: BookishRecordKind.book,
      properties: [
        BookishRecordKey.name: .string("The Glass Orbit"),
        BookishRecordKey.asin: .string("B000000001"),
      ])
    let imported = BookishImportResult(
      sourceID: KindleLibraryImporter.sourceID, records: [proposed])

    let plan = try BookishImportReconciler().plan(imported: imported, existing: [existing])
    #expect(plan.reviewEntries.count == 1)
    #expect(plan.defaultChoices == [proposed.id: .useExisting(existing.id)])
    #expect(throws: BookishImportPlanError.self) { try plan.resolve(choices: [:]) }
    #expect(try plan.resolve(choices: [proposed.id: .create]).records.map(\.id) == [proposed.id])
    #expect(try plan.resolve(choices: [proposed.id: .useExisting(existing.id)]).records.isEmpty)
  }

  @Test
  func changedInterchangeRecordNeedsAChoice() throws {
    let proposed = record("shared-id", kind: BookishRecordKind.book, name: "Imported title")
    let existing = record("shared-id", kind: BookishRecordKind.book, name: "My title")
    let imported = BookishImportResult(
      sourceID: BookishInterchangeImporter.sourceID, records: [proposed])

    let plan = try BookishImportReconciler().plan(imported: imported, existing: [existing])
    #expect(plan.reviewEntries.count == 1)
    #expect(plan.defaultChoices == [proposed.id: .keepExisting])
    #expect(try plan.resolve(choices: [proposed.id: .keepExisting]).records.isEmpty)
    #expect(try plan.resolve(choices: [proposed.id: .replaceExisting]).records == [proposed])
  }

  @Test
  func bulkChoicesApplyToSelectedMatchesOnly() throws {
    let first = record("proposed-a", kind: BookishRecordKind.person, name: "Ada Sol")
    let second = record("proposed-b", kind: BookishRecordKind.person, name: "Mina Reed")
    let existingFirst = record("manual-a", kind: BookishRecordKind.person, name: "Ada Sol")
    let existingSecond = record("manual-b", kind: BookishRecordKind.person, name: "Mina Reed")
    let plan = try BookishImportReconciler().plan(
      imported: BookishImportResult(
        sourceID: BookishInterchangeImporter.sourceID, records: [first, second]),
      existing: [existingFirst, existingSecond])

    #expect(
      plan.defaultChoices == [
        first.id: .useExisting(existingFirst.id),
        second.id: .useExisting(existingSecond.id),
      ])
    #expect(plan.choices(for: [first.id], preferring: .imported) == [first.id: .create])
    #expect(
      plan.choices(for: [first.id], preferring: .existing) == [
        first.id: .useExisting(existingFirst.id)
      ])
  }

  @Test
  func defaultExistingChoiceIsStableWithMultipleCandidates() throws {
    let proposed = record("proposed", kind: BookishRecordKind.person, name: "Ada Sol")
    let later = record("manual-z", kind: BookishRecordKind.person, name: "Ada Sol")
    let earlier = record("manual-a", kind: BookishRecordKind.person, name: "Ada Sol")
    let plan = try BookishImportReconciler().plan(
      imported: BookishImportResult(
        sourceID: BookishInterchangeImporter.sourceID, records: [proposed]),
      existing: [later, earlier])

    #expect(plan.defaultChoices[proposed.id] == .useExisting(earlier.id))
  }

  @Test
  func skippedNewRecordsAreOmittedAndUnlinked() throws {
    let author = record("author", kind: BookishRecordKind.person, name: "Ada Sol")
    let editor = record("editor", kind: BookishRecordKind.person, name: "Bea Lune")
    let book = BookishRecord(
      id: BookishRecordID("book"), kind: BookishRecordKind.book,
      properties: [
        BookishRecordKey.name: .string("The Glass Orbit"),
        BookishRecordKey.authors: .list([.record(author.id), .record(editor.id)]),
        "editor": .record(editor.id),
      ])
    let plan = try BookishImportReconciler().plan(
      imported: BookishImportResult(
        sourceID: BookishInterchangeImporter.sourceID, root: editor.id,
        records: [author, editor, book]),
      existing: [])

    #expect(plan.newEntries.map(\.id) == [author.id, editor.id, book.id])
    let resolved = try plan.resolve(choices: [editor.id: .skip])

    #expect(resolved.records.map(\.id) == [author.id, book.id])
    let written = try #require(resolved.records.last)
    #expect(written.list(BookishRecordKey.authors) == [.record(author.id)])
    #expect(written.properties["editor"] == nil)
    #expect(resolved.root == nil)
    #expect(throws: BookishImportPlanError.invalidChoice(book.id)) {
      try plan.resolve(choices: [book.id: .keepExisting])
    }
  }

  @Test
  func resolutionAuditsEachTreatmentAndOmitsSkippedAndPrunedRecords() throws {
    let sourceID = KindleLibraryImporter.sourceID
    let matchedAuthor = record("kindle-author", kind: BookishRecordKind.person, name: "Ada Sol")
    let existingAuthor = record("manual-author", kind: BookishRecordKind.person, name: "Ada Sol")
    let skippedBooksAuthor = record(
      "kindle-other-author", kind: BookishRecordKind.person, name: "Bea Lune", source: sourceID)
    let added = book("kindle-added", authors: [matchedAuthor.id])
    let skipped = book("kindle-skipped", authors: [skippedBooksAuthor.id])
    let kept = book("kindle-kept", authors: [])
    let replaced = book("kindle-replaced", authors: [])
    let existingKept = BookishRecord(
      id: kept.id, kind: BookishRecordKind.book,
      properties: [BookishRecordKey.name: .string("Old title")])
    let existingReplaced = BookishRecord(
      id: replaced.id, kind: BookishRecordKind.book,
      properties: [BookishRecordKey.name: .string("Old title")])
    let plan = try BookishImportReconciler().plan(
      imported: BookishImportResult(
        sourceID: sourceID,
        records: [matchedAuthor, skippedBooksAuthor, added, skipped, kept, replaced]),
      existing: [existingAuthor, existingKept, existingReplaced])

    let resolved = try plan.resolve(choices: [
      matchedAuthor.id: .useExisting(existingAuthor.id),
      skipped.id: .skip,
      kept.id: .keepExisting,
      replaced.id: .replaceExisting,
    ])

    #expect(
      resolved.treatments == [
        .added: [added.id], .replaced: [replaced.id], .kept: [kept.id],
        .matched: [existingAuthor.id],
      ])
    let date = Date(timeIntervalSince1970: 1_000_000)
    let list = try #require(
      try resolved.auditList(
        id: BookishRecordID("import-audit"), name: "Kindle Import", sourceID: sourceID,
        date: date))
    #expect(list.kind == BookishRecordKind.list)
    #expect(list.string(BookishRecordKey.name) == "Kindle Import")
    #expect(list.date(BookishRecordKey.importDate) == date)
    #expect(list.list(BookishRecordKey.importAdded) == [.record(added.id)])
    #expect(list.list(BookishRecordKey.importReplaced) == [.record(replaced.id)])
    #expect(list.list(BookishRecordKey.importKept) == [.record(kept.id)])
    #expect(list.list(BookishRecordKey.importMatched) == [.record(existingAuthor.id)])
  }

  @Test
  func resolutionWithEveryRecordSkippedHasNoAuditList() throws {
    let proposed = book("book", authors: [])
    let plan = try BookishImportReconciler().plan(
      imported: BookishImportResult(
        sourceID: BookishInterchangeImporter.sourceID, records: [proposed]),
      existing: [])

    let resolved = try plan.resolve(choices: [proposed.id: .skip])

    #expect(resolved.treatments.isEmpty)
    #expect(
      try resolved.auditList(
        id: BookishRecordID("import-audit"), name: "Import", sourceID: plan.sourceID,
        date: .now) == nil)
  }

  private func book(_ id: String, authors: [BookishRecordID]) -> BookishRecord {
    BookishRecord(
      id: BookishRecordID(id), kind: BookishRecordKind.book,
      properties: [
        BookishRecordKey.name: .string(id),
        BookishRecordKey.authors: .list(authors.map { .record($0) }),
      ])
  }

  private func record(
    _ id: String, kind: String, name: String, source: String? = nil
  ) -> BookishRecord {
    var properties: [String: BookishRecordValue] = [BookishRecordKey.name: .string(name)]
    if let source { properties[BookishRecordKey.source] = .string(source) }
    return BookishRecord(id: BookishRecordID(id), kind: kind, properties: properties)
  }
}
