//
//  Document.swift
//  Bookish
//
//  Created by Sam Deane on 17/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Cocoa
import BookishModel

class CollectionDocument: PersistentDocument {
    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        let viewModel = CollectionDocumentViewModel(document: self)
        let windowController = Application.sharedInstance.createDocumentWindowController(with: viewModel)
        self.addWindowController(windowController)
    }

}
