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

    override init() {
        super.init()
    }
    
    init(type typeName: String) throws {
        super.init()
        if Application.sharedInstance.testDocument {
            if let context = self.managedObjectContext {
                let formatter = DateFormatter()
                formatter.setLocalizedDateFormatFromTemplate("dd/MM/yy")
                
                let sharedEditor = Person(context: context)
                let entry = sharedEditor.role(as: Role.Default.editorName)

                let book = Book(context: context)
                book.name = "A Book"
                book.notes = "Some\nmulti\nline\nnotes."
                entry.addToBooks(book)

                for n in 1...3 {
                    let book = Book(context: context)
                    book.name = "Book \(n)"
                    book.notes = "This is an example book."
                    book.published = formatter.date(from: "12/11/69")
                    entry.addToBooks(book)
                    let illustrator = Person(context: context)
                    let entry2 = illustrator.role(as: Role.Default.illustratorName)
                    entry2.addToBooks(book)
                }
                
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
