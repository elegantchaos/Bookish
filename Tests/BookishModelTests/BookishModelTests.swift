// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XCTest
import CoreData
@testable import BookishModel

class BookishModelTests: XCTestCase {
    
    func makeTestContainer() -> CollectionContainer {
        let container = CollectionContainer(name: "Collection")
        container.persistentStoreDescriptions[0].url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores { (description, error) in
            XCTAssertNil(error)
        }
        return container
    }
    
    func testLoadingModel() {
        let model = BookishModel.loadModel()
        XCTAssertNotNil(model)
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
        let entry1 = person.role(as: "editor")
        XCTAssertEqual(entry1.person, person)
        XCTAssertEqual(entry1.role?.name, "editor")
        let entry2 = person.role(as: "editor")
        XCTAssertTrue(entry1 === entry2)
    }
    
    func testBookPersonLinkages() {
        let container = makeTestContainer()
        let context = container.viewContext
        let book = Book(context: context)
        let person1 = Person(context: context)
        let person2 = Person(context: context)
        let person3 = Person(context: context)
        
        let entry1 = person1.role(as: "editor")
        entry1.addToBooks(book)
        let entry2 = person1.role(as: "author")
        entry2.addToBooks(book)
        let entry3 = person2.role(as: "editor")
        entry3.addToBooks(book)

        if let people = book.personRoles {
            XCTAssertTrue(people.contains(entry1))
            XCTAssertTrue(people.contains(entry2))
            XCTAssertTrue(people.contains(entry3))
        } else {
            XCTFail("book has no people")
        }
        
        XCTAssertTrue(person1.personRoles!.contains(entry1))
        XCTAssertTrue(person1.personRoles!.contains(entry2))
        XCTAssertTrue(person2.personRoles!.contains(entry3))
        
        let allRoles = book.roles
        let authorRole = Role.role(named: "author", context: context)
        let editorRole = Role.role(named: "editor", context: context)
        let illustratorRole = Role.role(named: "illustrator", context: context)
        XCTAssertTrue(allRoles.contains(authorRole))
        XCTAssertTrue(allRoles.contains(editorRole))
        XCTAssertFalse(allRoles.contains(illustratorRole))

        let allPeople = book.people
        
        XCTAssertTrue(allPeople.contains(person1))
        XCTAssertTrue(allPeople.contains(person2))
        XCTAssertFalse(allPeople.contains(person3))

    }
}
