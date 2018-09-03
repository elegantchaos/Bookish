// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XCTest
import CoreData
@testable import BookishModel

class BookishModelTests: XCTestCase {
    
    func makeTestContainer() -> PersistentContainer {
        let container = PersistentContainer(name: "Collection")
        container.persistentStoreDescriptions[0].url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores { (description, error) in
            XCTAssertNil(error)
        }
        return container
    }
    
    func testContainer() {
        let container = makeTestContainer()
        let context = container.viewContext
        let book = Book(context: context)
        book.name = "Test"
        book.notes = "Test"
        context.insert(book)
        
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    func testUniqueRoles() {
        let container = makeTestContainer()
        let context = container.viewContext
        let role1 = Role.role(named: "author", context: context)
        XCTAssertEqual(role1.name, "author")
        let role2 = Role.role(named: "author", context: context)
        XCTAssertTrue(role1 === role2)
    }
    
    func testUniquePersonRoles() {
        let container = makeTestContainer()
        let context = container.viewContext
        let person = Person(context: context)
        let entry1 = person.entry(role: "editor")
        XCTAssertEqual(entry1.person, person)
        XCTAssertEqual(entry1.role?.name, "editor")
        let entry2 = person.entry(role: "editor")
        XCTAssertTrue(entry1 === entry2)
    }
}
