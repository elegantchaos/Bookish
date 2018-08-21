//
//  IndexViewController.swift
//  BookishMac
//
//  Created by Sam Deane on 21/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Cocoa
import BookishModel

class IndexViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet var indexArray: NSArrayController!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if let context = document.managedObjectContext {
            let example = Edition(context: context)
            example.name = "Test"

            let example2 = Edition(context: context)
            example2.name = "Test2"

            indexArray.managedObjectContext = context
            indexArray.fetch(self)
        }
        
//        tableView.reloadData()
    }
    
}
