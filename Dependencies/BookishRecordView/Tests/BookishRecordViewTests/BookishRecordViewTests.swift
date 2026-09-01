import BookishDatastore
import BookishRecord
import SwiftUI
import XCTest

@testable import BookishRecordView

final class BookishRecordViewTests: XCTestCase {
  func testPresentationUsesLayoutFields() {
    let presentation = BookishRecordPresentation(
      record: BookishRecord(
        kind: "book",
        properties: [
          "title": .string("Bookish"),
          "author": .string("Author"),
          "status": .string("Reading"),
        ]
      ),
      layout: BookishRecord(
        kind: "layout",
        properties: [
          "title": .string("Book Summary"),
          "fields": .list([.string("author"), .string("status")]),
        ]
      )
    )

    XCTAssertEqual(presentation.title, "Bookish")
    XCTAssertEqual(presentation.layoutTitle, "Book Summary")
    XCTAssertEqual(presentation.fields.map(\.key), ["author", "status"])
    XCTAssertEqual(presentation.fields.map(\.value), ["Author", "Reading"])
    XCTAssertEqual(presentation.fields.map(\.rawValue), [.string("Author"), .string("Reading")])
  }

  func testPresentationFallsBackToSortedRecordFieldsWithoutLayout() {
    let presentation = BookishRecordPresentation(
      record: BookishRecord(
        kind: "book",
        properties: [
          "status": .string("Reading"),
          "author": .string("Author"),
        ]
      ),
      layout: nil
    )

    XCTAssertEqual(presentation.layoutTitle, "Default")
    XCTAssertEqual(presentation.fields.map(\.key), ["author", "status"])
  }

  func testMutationPresentationDescribesSetPropertyMutation() {
    let mutation = MutationRecord(
      id: MutationID("mutation-1"),
      operation: .setProperty(
        recordID: BookishRecordID("book-1"),
        kind: "book",
        key: "reading_status",
        value: .string("Reading")
      )
    )

    let presentation = BookishMutationPresentation(mutation: mutation)

    XCTAssertEqual(presentation.title, "Set Reading Status")
    XCTAssertEqual(presentation.subtitle, "book · book-1")
    XCTAssertEqual(
      presentation.fields.map(\.key),
      [
        "operation", "recordID", "kind", "property", "value",
      ])
    XCTAssertEqual(
      presentation.fields.map(\.value),
      [
        "Set Property", "book-1", "book", "reading_status", "Reading",
      ])
  }

  @MainActor
  func testRecordViewCanBeConstructedWithRecordAndLayout() {
    let view = BookishRecordView(
      record: BookishRecord(
        kind: "book",
        properties: [
          "title": .string("Bookish"),
          "author": .record(BookishRecordID("author-1")),
        ]),
      layout: BookishRecord(
        kind: "layout",
        properties: ["fields": .list([.string("title"), .string("author")])]
      ),
      customValueView: { field in
        guard let id = field.rawValue?.recordValue else {
          return nil
        }

        return AnyView(Button(id.rawValue) {})
      }
    )

    XCTAssertNotNil(view.body)
  }

  @MainActor
  func testRecordCellCanBeConstructedWithRecordAndLayout() {
    let view = BookishRecordCell(
      record: BookishRecord(kind: "book", properties: ["title": .string("Bookish")]),
      layout: BookishRecord(kind: "layout", properties: ["fields": .list([.string("title")])])
    )

    XCTAssertNotNil(view.body)
  }

  @MainActor
  func testMutationViewsCanBeConstructedWithMutation() {
    let mutation = MutationRecord(
      operation: .deleteRecord(BookishRecordID("book-1"))
    )

    let cell = BookishMutationCell(mutation: mutation)
    let detail = BookishMutationView(mutation: mutation)

    XCTAssertNotNil(cell.body)
    XCTAssertNotNil(detail.body)
  }
}
