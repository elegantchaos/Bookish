// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel
import Dispatch

class PersonDetailViewController: DetailController<Person> {
    static let bookViewID = NSUserInterfaceItemIdentifier(rawValue: "book")
    static let roleViewID = NSUserInterfaceItemIdentifier(rawValue: "role")

    func selectedRelationships() -> [Relationship] {
        var result = [Relationship]()
        for person in selectedItems() {
            if let roles = person.relationships as? Set<Relationship> {
                result.append(contentsOf: roles)
            }
        }
        return result
    }

    override func rowsForSelection() -> [NSManagedObject] {
        var booksByRole = [Role:Set<Book>]()
        let selected = selectedRelationships()
        for relationship in selected {
            if let role = relationship.role, let prb = relationship.books as? Set<Book> {
                var books = booksByRole[role]
                if books == nil {
                    books = Set<Book>()
                    books?.formUnion(prb)
                    booksByRole[role] = books
                } else {
                    books?.formIntersection(prb)
                }
            }
        }
        
        var rows: [NSManagedObject] = []
        for role in Role.allRoles(context: cvm.managedObjectContext) {
            if let books = booksByRole[role] {
                rows.append(role)
                rows.append(contentsOf: books)
            }
        }
        
        return rows
    }
    
    
    override func identifier(for item: NSManagedObject) -> NSUserInterfaceItemIdentifier {
        switch item {
        case is Role:
            return PersonDetailViewController.roleViewID
        case is Book:
            return PersonDetailViewController.bookViewID
        default:
            return super.identifier(for: item)
        }
    }
}
