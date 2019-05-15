// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import AppKit
import BookishModel

class CollectionDocument: NSPersistentDocument {
    var collection: SyncedCollection!
    
    override open var managedObjectModel: NSManagedObjectModel {
        return BookishModel.model()
    }
    
    override class var autosavesInPlace: Bool {
        return true
    }

    override init() {
        super.init()
        self.fileType = NSSQLiteStoreType
//        managedObjectContext = collection.managedObjectContext
    }
    
    init(type typeName: String) throws {
        super.init()
        self.fileType = NSSQLiteStoreType
    }

    override func configurePersistentStoreCoordinator(for url: URL, ofType fileType: String, modelConfiguration configuration: String?, storeOptions: [String : Any]? = nil) throws {
        let application = Application.sharedInstance
        let mode = application.mode
        collection = SyncedCollection(url: url, identifier: application.cloudManager.collectionIdentifier, mode: mode) { (collection, error) in
            if let error = error {
                fatalError("failed to load \(error)")
            }
            
            self.managedObjectContext = collection.managedObjectContext
        }
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
    
    
    override func makeWindowControllers() {
        let viewModel = CollectionViewState(collection: self.collection)
        let windowController = Application.sharedInstance.windowControllerFactory.instantiateController(for: viewModel)
        self.addWindowController(windowController)
    }

}
