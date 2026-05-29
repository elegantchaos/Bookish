import BookishDatastore
import SwiftUI
import XCTest

@testable import BookishRecordView

final class BookishRecordViewTests: XCTestCase {
  func testPresentationUsesLayoutFields() {
    let presentation = PrototypeRecordPresentation(
      record: StoredRecord(
        kind: "book",
        properties: [
          "title": .string("Prototype"),
          "author": .string("Author"),
          "status": .string("Reading"),
        ]
      ),
      layout: StoredRecord(
        kind: "layout",
        properties: [
          "title": .string("Book Summary"),
          "fields": .list([.string("author"), .string("status")]),
        ]
      )
    )

    XCTAssertEqual(presentation.title, "Prototype")
    XCTAssertEqual(presentation.layoutTitle, "Book Summary")
    XCTAssertEqual(presentation.fields.map(\.key), ["author", "status"])
    XCTAssertEqual(presentation.fields.map(\.value), ["Author", "Reading"])
  }

  func testPresentationFallsBackToSortedRecordFieldsWithoutLayout() {
    let presentation = PrototypeRecordPresentation(
      record: StoredRecord(
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

  @MainActor
  func testRecordViewCanBeConstructedWithRecordAndLayout() {
    let view = PrototypeRecordView(
      record: StoredRecord(kind: "book", properties: ["title": .string("Prototype")]),
      layout: StoredRecord(kind: "layout", properties: ["fields": .list([.string("title")])])
    )

    XCTAssertNotNil(view.body)
  }

  @MainActor
  func testRecordCellCanBeConstructedWithRecordAndLayout() {
    let view = PrototypeRecordCell(
      record: StoredRecord(kind: "book", properties: ["title": .string("Prototype")]),
      layout: StoredRecord(kind: "layout", properties: ["fields": .list([.string("title")])])
    )

    XCTAssertNotNil(view.body)
  }
}
