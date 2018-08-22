//
//  ViewExtensions.swift
//  BookishMac
//
//  Created by Sam Deane on 21/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import AppKit

extension NSViewController {
    var application: Application {
        return NSApp.delegate as! Application
    }
    
    @objc var document: CollectionDocument {
        get {
            if let document = self.view.window?.windowController?.document as? CollectionDocument {
                return document
            } else if let document = application.documentBeingCreated {
                return document
            }
            
            fatalError("View has no associated document.")
        }
        
    }
}
