//
//  CollectionSplitViewController.swift
//  BookishMac
//
//  Created by Sam Deane on 22/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Cocoa

class CollectionSplitViewController: NSSplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        print("split preparing")
    }

}
