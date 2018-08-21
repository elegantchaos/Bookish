//
//  WindowController.swift
//  BookishMac
//
//  Created by Sam Deane on 21/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    
    
    override func windowDidLoad() {
        print("\(storyboard)")
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    override var document: AnyObject? { didSet {
        print("blah")
        } }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        NSLog("blah")
    }
}
