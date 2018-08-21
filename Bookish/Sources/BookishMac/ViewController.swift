//
//  ViewController.swift
//  Bookish
//
//  Created by Sam Deane on 17/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewWillAppear() {
        super.viewWillAppear()
        print("root vc document is \(document)")
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
    }
    
    override var representedObject: Any? {
        didSet {
            NSLog("blah")
        // Update the view, if already loaded.
        }
    }


}

