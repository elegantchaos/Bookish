// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import AppKit
import BookishModel

class CollectionDocument: NSPersistentDocument {
    let collection = SyncedCollection(identifier: Application.sharedInstance.cloud.collectionIdentifier)
    
    override open var managedObjectModel: NSManagedObjectModel {
        return BookishModel.loadModel()
    }
    
    override class var autosavesInPlace: Bool {
        return true
    }

    override init() {
        super.init()
        managedObjectContext = collection.managedObjectContext
    }
    
    init(type typeName: String) throws {
        super.init()
        
        let context = collection.managedObjectContext
        managedObjectContext = context
        makeDefaultRoles(context: context)
        
        if Application.sharedInstance.testDocument {
            BookishCollection.setupTestDocument(context: context)
        }
        Application.sharedInstance.testDocument = false
    }

    override func configurePersistentStoreCoordinator(for url: URL, ofType fileType: String, modelConfiguration configuration: String?, storeOptions: [String : Any]? = nil) throws {
        collection.configure(for: url, ofType: fileType, modelConfiguration: configuration, storeOptions: storeOptions)
        try super.configurePersistentStoreCoordinator(for: url, ofType: fileType, modelConfiguration: configuration, storeOptions: storeOptions)
    }
    
    func replaceContext() -> NSManagedObjectContext {
        guard let defaultContext = managedObjectContext else {
            fatalError("no context")
        }
        
        // replace the context with our own
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = defaultContext.persistentStoreCoordinator
        context.mergePolicy = defaultContext.mergePolicy
        self.managedObjectContext = context
        return context
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
