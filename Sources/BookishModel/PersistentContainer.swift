//
//  PersistentContainer.swift
//  Bookish
//
//  Created by Sam Deane on 20/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import CoreData

public class PersistentContainer: NSPersistentContainer {

    public override class func defaultDirectoryURL() -> URL {
        return super.defaultDirectoryURL().appendingPathComponent("BookishModel")
    }
    
    public override init(name: String, managedObjectModel model: NSManagedObjectModel) {
        super.init(name: name, managedObjectModel: model)
        
//        let description = NSPersistentStoreDescription(url: PersistentContainer.defaultDirectoryURL())
//        description.shouldAddStoreAsynchronously = true
//        self.persistentStoreDescriptions = [description]
        
//        self.persistentStoreDescriptions[0].shouldAddStoreAsynchronously = true
    }
}
