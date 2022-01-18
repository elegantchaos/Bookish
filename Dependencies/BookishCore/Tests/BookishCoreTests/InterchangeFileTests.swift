// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XCTest
import XCTestExtensions

@testable import BookishCore

class InterchangeFileTests: XCTestCase {
    
    func testWritingEmpty() {
        let type = InterchangeFileType("test", version: 1)
        let creator = InterchangeCreator(id: "some.app", version: "1.0", build: 1, commit: "sha-hash-here")
        let container = InterchangeContainer()
        let file = InterchangeFile(type: type, creator: creator, content: container)
        
        do {
            let data = try file.encode()
            let json = String(data: data, encoding: .utf8)
            if Self.emptyFileJSON != json {
                XCTFail("JSON didn't match")
                print(json!)
            }
        } catch {
            XCTFail("encoding failed")
        }
    }

    func testWritingRecords() {
        let type = InterchangeFileType("test", version: 1, variant: .compact)
        let creator = InterchangeCreator(id: "some.app", version: "1.0", build: 1, commit: "sha-hash-here")
        let container = InterchangeContainer()
        
        var book1 = InterchangeRecord(.init(id: "1", name: "book 1", kind: "book"))
        book1["isbn"] = 124523434
        
        var book2 = InterchangeRecord(.init(id: "2", name: "book 2", kind: "book"))
        book2["subtitle"] = "A subtitle"

        container.add(book1)
        container.add(book2)
        let file = InterchangeFile(type: type, creator: creator, content: container)
        
        do {
            let data = try file.encode()
            let json = String(data: data, encoding: .utf8)!
            if Self.recordsJSON != json {
                XCTAssertEqualLineByLine(Self.recordsJSON, json)
            }
        } catch {
            XCTFail("encoding failed")
        }
    }

}



extension InterchangeFileTests {
    static let emptyFileJSON = """
{
  "content" : [

  ],
  "creator" : {
    "build" : 1,
    "commit" : "sha-hash-here",
    "id" : "some.app",
    "version" : "1.0"
  },
  "type" : {
    "format" : "test",
    "version" : 1
  }
}
"""

    static let recordsJSON = """
{
  "content" : [
    {
      "id" : "1",
      "isbn" : 124523434,
      "items" : [

      ],
      "kind" : "book",
      "links" : [

      ],
      "name" : "book 1"
    },
    {
      "id" : "2",
      "items" : [

      ],
      "kind" : "book",
      "links" : [

      ],
      "name" : "book 2",
      "subtitle" : "A subtitle"
    }
  ],
  "creator" : {
    "build" : 1,
    "commit" : "sha-hash-here",
    "id" : "some.app",
    "version" : "1.0"
  },
  "type" : {
    "format" : "test",
    "variant" : "compact",
    "version" : 1
  }
}
"""
    
}
