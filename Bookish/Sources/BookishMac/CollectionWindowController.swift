//
//  WindowController.swift
//  BookishMac
//
//  Created by Sam Deane on 21/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Cocoa

class CollectionWindowController: NSWindowController {
    var viewModel: CollectionDocumentViewModel?
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        NSLog("blah")
    }
}
