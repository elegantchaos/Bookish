//
//  BookishModelMobileTests.swift
//  BookishModelMobileTests
//
//  Created by Sam Deane on 20/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import XCTest
@testable import BookishModel

class BookishModelTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        let test = BookishModel()
        XCTAssertEqual(test.test(), "blah")
    }

}
