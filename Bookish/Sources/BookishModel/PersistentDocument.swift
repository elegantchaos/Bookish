//
//  PersistentDocument.swift
//  Bookish
//
//  Created by Sam Deane on 20/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import AppKit

open class PersistentDocument: NSPersistentDocument {
    override open var managedObjectModel: NSManagedObjectModel { get {
        if let url = Bundle(for: PersistentDocument.self).url(forResource: "Document", withExtension: "momd") {
            if let model = NSManagedObjectModel(contentsOf: url) {
                return model
            }
        }
        fatalError("boom")
        }
    }
}
