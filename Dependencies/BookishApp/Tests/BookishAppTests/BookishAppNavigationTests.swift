import BookishDatastore
import BookishRecord
import Commands
import Foundation
import Testing

@testable import BookishApp

@MainActor extension BookishAppTests {
  @Test
  func selectionCommandsAreDisabledWithoutSelection() {
    let harness = makeUIState()
    let commander = makeCommandCentre(for: harness)

    #expect(commander.availability(MarkReadingCommand()) == .disabled)
    #expect(commander.availability(MarkFinishedCommand()) == .disabled)
    #expect(commander.availability(SimulateRemoteMutationCommand()) == .disabled)
  }

  @Test
  func navigationCommandsAreDisabledWithoutRecords() {
    let navigation = BookishNavigationService()
    let harness = makeUIState(navigation: navigation)
    let commander = makeCommandCentre(for: harness)

    #expect(commander.availability(SelectNextRecordIndexCommand()) == .disabled)
    #expect(commander.availability(SelectPreviousRecordIndexCommand()) == .disabled)
    #expect(commander.availability(SelectNextRecordCommand()) == .disabled)
    #expect(commander.availability(SelectPreviousRecordCommand()) == .disabled)
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
  func clearingRecordSelectionKeepsTheBrowserOnItsIndex() {
    let navigation = BookishNavigationService()
    let selectedRecordResult = RecordQueryResult(query: RecordQuery())
    selectedRecordResult.update(records: [
      BookishRecord(id: BookishRecordID("book-1"), kind: "book"),
      BookishRecord(id: BookishRecordID("book-2"), kind: "book"),
    ])
    navigation.update(selectedRecordResult: selectedRecordResult)
    navigation.select(recordID: BookishRecordID("book-2"))
    navigation.push(recordID: BookishRecordID("linked-book"))

    navigation.select(recordID: nil)

    #expect(navigation.selectedRecordID == nil)
    #expect(navigation.recordNavigationPath.isEmpty)

    navigation.update(selectedRecordResult: selectedRecordResult)

    #expect(navigation.selectedRecordID == nil)
  }

  @Test
  func liveQueryRemovalClearsSelectedDetailWithoutSelectingAnotherRecord() {
    let navigation = BookishNavigationService()
    let result = RecordQueryResult(query: RecordQuery(predicate: .kind("book")))
    let first = BookishRecord(id: BookishRecordID("book-1"), kind: "book")
    let second = BookishRecord(id: BookishRecordID("book-2"), kind: "book")
    result.update(records: [first, second])
    navigation.update(selectedRecordResult: result)
    navigation.select(recordID: second.id)
    navigation.push(recordID: BookishRecordID("linked-record"))

    result.update(records: [first])

    #expect(navigation.selectedRecordID == nil)
    #expect(navigation.recordNavigationPath.isEmpty)
    #expect(navigation.selectedRecordIDs == [first.id])

    result.update(records: [first, second])
    #expect(navigation.selectedRecordID == nil)
  }

  @Test
  func liveQueryChangePreservesSelectionWhileItsRecordRemains() {
    let navigation = BookishNavigationService()
    let result = RecordQueryResult(query: RecordQuery(predicate: .kind("book")))
    let first = BookishRecord(id: BookishRecordID("book-1"), kind: "book")
    let second = BookishRecord(id: BookishRecordID("book-2"), kind: "book")
    result.update(records: [first, second])
    navigation.update(selectedRecordResult: result)
    navigation.select(recordID: second.id)

    result.update(records: [second])

    #expect(navigation.selectedRecordID == second.id)
  }

  @Test
  func navigationStopsObservingThePreviousQueryResult() {
    let navigation = BookishNavigationService()
    let previous = RecordQueryResult(query: RecordQuery(predicate: .kind("book")))
    let active = RecordQueryResult(query: RecordQuery(predicate: .kind("author")))
    let book = BookishRecord(id: BookishRecordID("book-1"), kind: "book")
    let author = BookishRecord(id: BookishRecordID("author-1"), kind: "author")
    previous.update(records: [book])
    active.update(records: [author])
    navigation.update(selectedRecordResult: previous)
    navigation.update(selectedRecordResult: active)

    previous.update(records: [])

    #expect(navigation.selectedRecordID == author.id)
  }

  @Test
  func selectingMainSectionPreservesTheBrowserIndexAndClearsLinkedNavigation() throws {
    let navigation = BookishNavigationService()
    let recordIndexResult = RecordQueryResult(query: RecordQuery())
    recordIndexResult.update(
      records: [
        try browserIndexRecord(id: "books", name: "Books", predicate: .kind("book"))
      ])
    navigation.update(recordIndexResult: recordIndexResult)
    navigation.push(recordID: BookishRecordID("book-1"))

    navigation.select(mainSection: .capture)

    #expect(navigation.selectedMainSection == .capture)
    #expect(navigation.selectedRecordIndexName == "Books")
    #expect(navigation.recordNavigationPath.isEmpty)
  }

  @Test
  func navigationRestoresPersistedWorkflowSelection() throws {
    let suiteName = "BookishAppNavigationTests-\(UUID().uuidString)"
    let settings = try #require(UserDefaults(suiteName: suiteName))
    defer { settings.removePersistentDomain(forName: suiteName) }
    settings.set(.mainSection(.lookup), forKey: .lastNavigationSelection)

    let navigation = BookishNavigationService(settings: settings)

    #expect(navigation.selectedMainSection == .lookup)
  }

  @Test
  func navigationRestoresPersistedRecordIndexWhenAvailable() throws {
    let suiteName = "BookishAppNavigationTests-\(UUID().uuidString)"
    let settings = try #require(UserDefaults(suiteName: suiteName))
    defer { settings.removePersistentDomain(forName: suiteName) }
    settings.set(.recordIndex(BookishRecordID("books")), forKey: .lastNavigationSelection)
    let navigation = BookishNavigationService(settings: settings)
    let recordIndexResult = RecordQueryResult(query: RecordQuery())
    recordIndexResult.update(
      records: [
        try browserIndexRecord(id: "authors", name: "Authors", predicate: .kind("author")),
        try browserIndexRecord(id: "books", name: "Books", predicate: .kind("book")),
      ])

    navigation.update(recordIndexResult: recordIndexResult)

    #expect(navigation.selectedRecordIndexID == BookishRecordID("books"))
  }

  @Test
  func navigationPersistsResolvedRecordIndexSelection() throws {
    let suiteName = "BookishAppNavigationTests-\(UUID().uuidString)"
    let settings = try #require(UserDefaults(suiteName: suiteName))
    defer { settings.removePersistentDomain(forName: suiteName) }
    let navigation = BookishNavigationService(settings: settings)
    let recordIndexResult = RecordQueryResult(query: RecordQuery())
    recordIndexResult.update(
      records: [
        try browserIndexRecord(id: "books", name: "Books", predicate: .kind("book"))
      ])

    navigation.update(recordIndexResult: recordIndexResult)

    #expect(
      settings.value(forKey: .lastNavigationSelection) == .recordIndex(BookishRecordID("books")))
  }

  @Test
  func navigationCommandsMoveBetweenIndexesAndRecords() async throws {
    let harness = try makeHarness()
    let commander = makeCommandCentre(for: harness)
    await harness.load()
    try await harness.navigation.select(recordIndexID: BookishRecordID("datastore-index-layouts"))

    try await commander.perform(SelectNextRecordIndexCommand())

    #expect(harness.navigation.selectedRecordIndexName == "Indexes")

    try await commander.perform(SelectPreviousRecordIndexCommand())

    #expect(harness.navigation.selectedRecordIndexName == "Layouts")

    let navigation = BookishNavigationService()
    let navigationCommander = makeCommandCentre(for: makeUIState(navigation: navigation))
    let selectedRecordResult = RecordQueryResult(query: RecordQuery())
    selectedRecordResult.update(records: [
      BookishRecord(id: BookishRecordID("book-1"), kind: "book"),
      BookishRecord(id: BookishRecordID("book-2"), kind: "book"),
    ])
    navigation.update(selectedRecordResult: selectedRecordResult)
    navigation.select(recordID: BookishRecordID("book-1"))

    try await navigationCommander.perform(SelectNextRecordCommand())

    #expect(navigation.selectedRecordID == BookishRecordID("book-2"))

    try await navigationCommander.perform(SelectPreviousRecordCommand())

    #expect(navigation.selectedRecordID == BookishRecordID("book-1"))
  }

  @Test
  func nameFilterComposesWithTheSelectedIndexQuery() async throws {
    let harness = try makeHarness()
    await harness.load()

    try await harness.navigation.select(recordIndexID: BookishRecordID("datastore-index-books"))
    try await harness.navigation.setRecordNameFilter("left hand")

    #expect(harness.navigation.recordNameFilter == "left hand")
    #expect(
      harness.navigation.selectedRecordResult?.query
        == RecordQuery(
          predicate: .and([
            .kind(BookishRecordKind.book),
            .propertyStringContains(BookishRecordKey.name, "left hand"),
          ]),
          sort: [.property(BookishRecordKey.name), .id]
        ))
    #expect(harness.navigation.selectedRecordIDs == [BookishRecordID("seed-book")])
  }

  @Test
  func selectedIndexProvidesDefaultLayout() async throws {
    let harness = try makeHarness()
    await harness.load()

    try await harness.navigation.select(recordIndexID: BookishRecordID("datastore-index-layouts"))

    let layout = try await harness.presentation.selectedLayout(
      for: harness.navigation.selectedRecordIndex)

    #expect(layout?.id == BookishRecordID("datastore-layout-layout"))
  }

  @Test
  func navigateToRecordCommandPushesTargetOutsideCurrentIndex() async throws {
    let navigation = BookishNavigationService()
    let commander = makeCommandCentre(for: makeUIState(navigation: navigation))
    let selectedRecordResult = RecordQueryResult(query: RecordQuery())
    selectedRecordResult.update(records: [
      BookishRecord(id: BookishRecordID("author-1"), kind: "author")
    ])
    navigation.update(selectedRecordResult: selectedRecordResult)

    try await commander.perform(NavigateToRecordCommand(recordID: BookishRecordID("book-1")))

    #expect(navigation.selectedRecordID == BookishRecordID("author-1"))
    #expect(navigation.recordNavigationPath == [BookishRecordID("book-1")])
  }

  @Test
  func navigateToRecordCommandCanSelectTargetInCurrentIndex() async throws {
    let navigation = BookishNavigationService()
    let commander = makeCommandCentre(for: makeUIState(navigation: navigation))
    let selectedRecordResult = RecordQueryResult(query: RecordQuery())
    selectedRecordResult.update(records: [
      BookishRecord(id: BookishRecordID("author-1"), kind: "author"),
      BookishRecord(id: BookishRecordID("book-1"), kind: "book"),
    ])
    navigation.update(selectedRecordResult: selectedRecordResult)

    try await commander.perform(
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
