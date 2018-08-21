//
//  Document.swift
//  Bookish
//
//  Created by Sam Deane on 17/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Cocoa
import BookishModel

class Document: PersistentDocument {
    var count: Int = 0
    
    override init() {
        super.init()
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override func save(_ sender: Any?) {
        let request = NSFetchRequest<Edition>(entityName: "Edition")
        count = try! managedObjectContext!.count(for: request)

        super.save(sender)
    }
    override func makeWindowControllers() {
        let application = NSApp.delegate as! Application
        application.documentBeingCreated = self
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! WindowController
        self.addWindowController(windowController)
        application.documentBeingCreated = nil
    }

}
