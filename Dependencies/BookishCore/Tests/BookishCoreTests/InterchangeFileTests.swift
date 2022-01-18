// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XCTest

@testable import BookishCore

class InterchangeFileTests: XCTestCase {
    
    func testWriting() {
        let type = InterchangeFileType("test", version: 1)
        let creator = InterchangeCreator(id: "some.app", version: "1.0", build: 1, commit: "sha-hash-here")
        let container = InterchangeContainer()
        let file = InterchangeFile(type: type, creator: creator, content: container)
        
        do {
            let data = try file.encode()
            let json = String(data: data, encoding: .utf8)
            print(json!)
            XCTAssertEqual(json, Self.emptyFileJSON)
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
    "variant" : {
      "normal" : {

      }
    },
    "version" : 1
  }
}
"""

}
