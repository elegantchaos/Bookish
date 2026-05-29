import BookishDatastore
import SwiftUI
import XCTest

@testable import BookishRecordView

final class BookishRecordViewTests: XCTestCase {
  @MainActor
  func testRecordViewCanBeConstructedWithRecordAndLayout() {
    let view = PrototypeRecordView(
      record: StoredRecord(kind: "book", properties: ["title": .string("Prototype")]),
      layout: StoredRecord(kind: "layout", properties: ["fields": .list([.string("title")])])
    )

    XCTAssertNotNil(view.body)
  }
}
