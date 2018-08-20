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
}
