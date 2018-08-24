//
//  ViewController.swift
//  Bookish
//
//  Created by Sam Deane on 17/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Cocoa

class CollectionViewController: NSViewController {
    @objc let cvm: CollectionDocumentViewModel
    
    required init?(coder: NSCoder) {
        self.cvm = Application.sharedInstance.documentWindowControllerFactory.connectViewModel()
        super.init(coder: coder)
    }
    
    @objc var document: CollectionDocument? {
        get {
            return cvm.document
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        CoreDataTransformers.updateCoreDataBindings(for: self.view, context: cvm.managedObjectContext)
    }
}

