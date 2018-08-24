//
//  CollectionDetailViewController.swift
//  BookishMac
//
//  Created by Sam Deane on 22/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Cocoa
import BookishModel

class CollectionDetailViewController: CollectionViewController {
    @IBOutlet weak var indexView: CollectionIndexViewController!
    @IBOutlet weak var indexArray: NSArrayController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: this is a bit naff as it makes assumptions about the containment hierarchy
        if let parent = self.parent as? NSSplitViewController {
            indexView = parent.splitViewItems[0].viewController as? CollectionIndexViewController
        }
    }
    
    override func viewWillAppear() {
        // we really should be able to bind the array to the object context in IB, but
        // the document value is set relatively late, so it's safer to do it here
//        if let context = document?.managedObjectContext {
//            indexArray.managedObjectContext = context
            indexArray.fetch(self)
//        }

        super.viewWillAppear()
    }
    
}
