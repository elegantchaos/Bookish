// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Cocoa
import BookishModel

class CollectionDocument: PersistentDocument {
    override class var autosavesInPlace: Bool {
        return true
    }

    init(type typeName: String) throws {
        super.init()
        if Application.sharedInstance.testDocument {
            if let context = self.managedObjectContext {
                let book1 = Book(context: context)
                book1.name = "Book 1"
                book1.notes = "This is an example book."
                let book2 = Book(context: context)
                book2.name = "Book 2"
                book2.notes = "Some\nmulti\nline\nnotes."
                let sharedEditor = Person(context: context)
                let entry = sharedEditor.role(as: "editor")
                entry.addToBooks(book1)
                entry.addToBooks(book2)
            }
            Application.sharedInstance.testDocument = false
        }
    }
    
    override func makeWindowControllers() {
        let viewModel = CollectionDocumentViewModel(document: self)
        let windowController = Application.sharedInstance.documentWindowControllerFactory.instantiateController(for: viewModel)
        self.addWindowController(windowController)
    }

}
