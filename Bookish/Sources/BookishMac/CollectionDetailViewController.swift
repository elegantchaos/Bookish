//
//  CollectionDetailViewController.swift
//  BookishMac
//
//  Created by Sam Deane on 22/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Cocoa
import BookishModel

class CollectionDetailViewController: NSViewController {
    @IBOutlet weak var indexView: CollectionIndexViewController!
    @IBOutlet var indexArray: NSArrayController!
    
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
        if let context = document?.managedObjectContext {
            indexArray.managedObjectContext = context
            indexArray.fetch(self)
        }
        
        super.viewWillAppear()
    }
    
    @objc static func keyPathsForValuesAffectingName() -> NSSet {
        return ["representedObject"]
    }
    
    @objc override var representedObject: Any? {
        didSet {
            print("rep obj changed to \(representedObject)")
        }
    }
    
    @objc var name: String? {
        get {
            if let objects = representedObject as? [Edition] {
                switch objects.count {
                case 0:
                    break
                case 1:
                    return objects[0].name
                default:
                    return "<multiple>"
                }
            }
            
            return nil
        }
        
        set(newName) {
            if let objects = representedObject as? [Edition] {
                objects.forEach {
                    $0.name = newName
                }
            }
        }
    }
}
