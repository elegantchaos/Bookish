// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

@objc class CollectionDocumentViewModel: NSObject, DocumentViewModel {
    typealias  WindowController = CollectionWindowController

    @objc let document: CollectionDocument
    @objc let managedObjectContext: NSManagedObjectContext
    @objc var selectedIndexes: Any?
    
    init(document: CollectionDocument) {
        self.document = document
        self.managedObjectContext = document.managedObjectContext!
    }
}
