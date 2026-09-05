// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Testing

@testable import BookishCore

struct BookRecordTests {
  @Test
  func readsNameAsTheBookTitle() throws {
    let record = try #require(
      BookRecord(
        [
          "id": "book-1",
          "name": "Snow Crash",
        ]
      )
    )

    #expect(record.title == "Snow Crash")
    #expect(BookKey.name.rawValue == "name")
    #expect(BookKey.allCases.map(\.rawValue).contains("title") == false)
  }
}
