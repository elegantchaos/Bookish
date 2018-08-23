//
//  CollectionDocumentViewModel.swift
//  BookishMac
//
//  Created by Sam Deane on 23/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import CoreData

@objc class CollectionDocumentViewModel: NSObject {
    @objc let document: CollectionDocument
    @objc let managedObjectContext: NSManagedObjectContext
    @objc var selectedIndexes: Any?
    
    init(document: CollectionDocument) {
        self.document = document
        self.managedObjectContext = document.managedObjectContext!
    }
}
