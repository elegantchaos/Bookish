//
//  BookishModelMobileTests.swift
//  BookishModelMobileTests
//
//  Created by Sam Deane on 20/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import XCTest
import CoreData
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

    func testContainer() {
        let container = PersistentContainer(name: "Document")
        container.persistentStoreDescriptions[0].url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores { (description, error) in
            XCTAssertNil(error)
        }
        
        let context = container.viewContext
        let edition = Edition(context: context)
        edition.name = "Test"
        edition.summary = "Test"
        context.insert(edition)
        
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
//        let fetch = NSFetch
    }
}
