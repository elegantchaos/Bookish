//
//  IndexViewController.swift
//  BookishMac
//
//  Created by Sam Deane on 21/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Cocoa
import BookishModel

class IndexViewController: NSViewController {
    @IBOutlet weak var indexArray: NSArrayController!
    
    override func viewWillDisappear() {
        indexArray.managedObjectContext = nil
        super.viewWillDisappear()
    }
    
    override func viewWillAppear() {
        // we really should be able to bind the array to the object context in IB, but
        // the document value is set relatively late, so it's safer to do it here
        if let context = document.managedObjectContext {
            indexArray.managedObjectContext = context
            indexArray.fetch(self)
        }

        super.viewWillAppear()
    }
    
}
