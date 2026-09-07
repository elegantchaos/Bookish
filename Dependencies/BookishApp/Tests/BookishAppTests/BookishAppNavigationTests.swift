import BookishDatastore
import BookishRecord
import Commands
import Foundation
import Testing

@testable import BookishApp

@MainActor extension BookishAppTests {
  @Test
  func selectionCommandsAreDisabledWithoutSelection() {
    let harness = BookishHarness()

    #expect(harness.availability(MarkReadingCommand()) == .disabled)
    #expect(harness.availability(MarkFinishedCommand()) == .disabled)
    #expect(harness.availability(SimulateRemoteMutationCommand()) == .disabled)
  }

  @Test
  func navigationCommandsAreDisabledWithoutRecords() {
    let harness = BookishHarness()
    let navigation = BookishNavigationService()

    #expect(harness.availability(SelectNextRecordIndexCommand()) == .disabled)
    #expect(harness.availability(SelectPreviousRecordIndexCommand()) == .disabled)
    #expect(navigation.availability(SelectNextRecordCommand()) == .disabled)
    #expect(navigation.availability(SelectPreviousRecordCommand()) == .disabled)
  }

  @Test
  func navigationServiceDefaultsToFirstIndexAndRecord() throws {
    let navigation = BookishNavigationService()
    let recordIndexResult = RecordQueryResult(query: RecordQuery())
    recordIndexResult.update(
      records: [
        try browserIndexRecord(id: "authors", name: "Authors", predicate: .kind("author")),
        try browserIndexRecord(id: "books", name: "Books", predicate: .kind("book")),
      ])
    let selectedRecordResult = RecordQueryResult(query: RecordQuery(predicate: .kind("author")))
    selectedRecordResult.update(records: [
      BookishRecord(id: BookishRecordID("author-1"), kind: "author")
    ])

    navigation.update(recordIndexResult: recordIndexResult)
    navigation.update(selectedRecordResult: selectedRecordResult)

    #expect(navigation.recordIndexes.map(\.name) == ["Authors", "Books"])
    #expect(navigation.selectedRecordIndexName == "Authors")
    #expect(navigation.selectedRecordID == BookishRecordID("author-1"))
    #expect(navigation.selectedRecordIDs == [BookishRecordID("author-1")])
  }

  @Test
  func navigationCommandsMoveBetweenIndexesAndRecords() async throws {
    let harness = try makeHarness()
    await harness.load()
    await harness.select(recordIndexID: BookishRecordID("datastore-index-layouts"))

    try await harness.perform(SelectNextRecordIndexCommand())

    #expect(harness.navigation.selectedRecordIndexName == "Indexes")

    try await harness.perform(SelectPreviousRecordIndexCommand())

    #expect(harness.navigation.selectedRecordIndexName == "Layouts")

    let navigation = BookishNavigationService()
    let selectedRecordResult = RecordQueryResult(query: RecordQuery())
    selectedRecordResult.update(records: [
      BookishRecord(id: BookishRecordID("book-1"), kind: "book"),
      BookishRecord(id: BookishRecordID("book-2"), kind: "book"),
    ])
    navigation.update(selectedRecordResult: selectedRecordResult)
    navigation.select(recordID: BookishRecordID("book-1"))

    try await navigation.perform(SelectNextRecordCommand())

    #expect(navigation.selectedRecordID == BookishRecordID("book-2"))

    try await navigation.perform(SelectPreviousRecordCommand())

    #expect(navigation.selectedRecordID == BookishRecordID("book-1"))
  }

  @Test
  func selectedIndexProvidesDefaultLayout() async throws {
    let harness = try makeHarness()
    await harness.load()

    await harness.select(recordIndexID: BookishRecordID("datastore-index-layouts"))

    let layout = try await harness.selectedLayout()

    #expect(layout?.id == BookishRecordID("datastore-layout-layout"))
  }

  @Test
  func navigateToRecordCommandPushesTargetOutsideCurrentIndex() async throws {
    let navigation = BookishNavigationService()
    let selectedRecordResult = RecordQueryResult(query: RecordQuery())
    selectedRecordResult.update(records: [
      BookishRecord(id: BookishRecordID("author-1"), kind: "author")
    ])
    navigation.update(selectedRecordResult: selectedRecordResult)

    try await navigation.perform(NavigateToRecordCommand(recordID: BookishRecordID("book-1")))

    #expect(navigation.selectedRecordID == BookishRecordID("author-1"))
    #expect(navigation.recordNavigationPath == [BookishRecordID("book-1")])
  }

  @Test
  func navigateToRecordCommandCanSelectTargetInCurrentIndex() async throws {
    let navigation = BookishNavigationService()
    let selectedRecordResult = RecordQueryResult(query: RecordQuery())
    selectedRecordResult.update(records: [
      BookishRecord(id: BookishRecordID("author-1"), kind: "author"),
      BookishRecord(id: BookishRecordID("book-1"), kind: "book"),
    ])
    navigation.update(selectedRecordResult: selectedRecordResult)

    try await navigation.perform(
      NavigateToRecordCommand(recordID: BookishRecordID("book-1"), mode: .currentIndex))

    #expect(navigation.selectedRecordID == BookishRecordID("book-1"))
    #expect(navigation.recordNavigationPath.isEmpty)
  }

  @Test
  func recordLinkPresentationUsesTheTargetNameImageAndKindIcon() throws {
    let imageURL = try #require(URL(string: "https://example.com/cover.jpg"))
    let target = BookishRecord(
      id: BookishRecordID("book-1"),
      kind: BookishRecordKind.book,
      properties: [
        BookishRecordKey.name: .string("The Left Hand of Darkness"),
        BookishRecordKey.image: try BookishRecordValue(url: imageURL),
      ])

    let presentation = BookishRecordLinkPresentation(
      record: target, placeholderSystemImage: "books.vertical")

    #expect(presentation.name == "The Left Hand of Darkness")
    #expect(presentation.imageURL == imageURL)
    #expect(presentation.placeholderSystemImage == "books.vertical")
  }
}
