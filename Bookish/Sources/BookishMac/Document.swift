//
//  Document.swift
//  Bookish
//
//  Created by Sam Deane on 17/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Cocoa
import BookishModel

class Document: NSPersistentDocument {
    let container: BookishPersistentContainer
    
    override init() {
        self.container = BookishPersistentContainer(name: "Document")
        super.init()
        
        container.loadPersistentStores { (description, err) in
            if let err = err {
//                os_log("error loading store \(description): \(err)")
                return
            }
        }
//        os_log("ok")
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
        self.addWindowController(windowController)
    }

}
