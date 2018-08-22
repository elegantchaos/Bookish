//
//  CollectionDetailViewController.swift
//  BookishMac
//
//  Created by Sam Deane on 22/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Cocoa

class CollectionDetailViewController: NSViewController {
    weak var indexView: CollectionIndexViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: this is a bit naff as it makes assumptions about the containment hierarchy
        if let parent = self.parent as? NSSplitViewController {
            indexView = parent.splitViewItems[0].viewController as? CollectionIndexViewController
        }
    }
    
    @objc override var representedObject: Any? {
        didSet {
            print("rep obj changed to \(representedObject)")
        }
    }
    
}
