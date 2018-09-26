// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import AppKit
import BookishModel

class CollectionDocument: NSPersistentDocument {
    override open var managedObjectModel: NSManagedObjectModel {
        return BookishModel.loadModel()
    }
    
    override class var autosavesInPlace: Bool {
        return true
    }

    override init() {
        super.init()
    }
    
    init(type typeName: String) throws {
        super.init()
        if let context = self.managedObjectContext {
            makeDefaultRoles(context: context)
            
            if Application.sharedInstance.testDocument {
                setupTestDocument(context: context)
            }
            Application.sharedInstance.testDocument = false
        }
    }
    
    /**
     A few roles should always be present.
     */
    
    func makeDefaultRoles(context: NSManagedObjectContext) {
        for role in Role.Default.names {
            _ = Role.role(named: role, context: context)
        }
    }
    
    /**
    Populate the document with some test data.
     */
    
    func setupTestDocument(context: NSManagedObjectContext) {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dd/MM/yy")
        
        let sharedEditor = Person(context: context)
        sharedEditor.name = "Ms Editor"
        sharedEditor.notes = "This person is the editor of a number of books."
        let entry = sharedEditor.role(as: Role.Default.editorName)
        
        let book = Book(context: context)
        book.name = "A Book"
        book.notes = "Some\nmulti\nline\nnotes."
        entry.addToBooks(book)
        
        sharedEditor.role(as: Role.Default.authorName).addToBooks(book)
        sharedEditor.role(as: Role.Default.illustratorName).addToBooks(book)

        for n in 1...3 {
            let book = Book(context: context)
            book.name = "Book \(n)"
            book.notes = "This is an example book."
            book.published = formatter.date(from: "12/11/69")
            entry.addToBooks(book)
            let illustrator = Person(context: context)
            illustrator.name = "Mr Illustrator \(n)"
            illustrator.notes = "Another example person."
            let entry2 = illustrator.role(as: Role.Default.illustratorName)
            entry2.addToBooks(book)
        }
    }
    
    override func makeWindowControllers() {
        let viewModel = CollectionDocumentViewModel(document: self)
        let windowController = Application.sharedInstance.documentWindowControllerFactory.instantiateController(for: viewModel)
        self.addWindowController(windowController)
    }

}
