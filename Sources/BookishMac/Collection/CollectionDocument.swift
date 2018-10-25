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
                Collection.setupTestDocument(context: context)
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
    
    override func makeWindowControllers() {
        let viewModel = CollectionDocumentViewModel(document: self)
        let windowController = Application.sharedInstance.documentWindowControllerFactory.instantiateController(for: viewModel)
        self.addWindowController(windowController)
    }

}
