//
//  Edition.swift
//  Bookish
//
//  Created by Sam Deane on 20/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Foundation
import CoreData

public class Edition: NSManagedObject {
    static var untitledCount = 0
    
    override public init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto:context)
    }
    
    public override func awakeFromInsert() {
        name = "Untitled \(Edition.untitledCount)"
        Edition.untitledCount += 1
    }
}
