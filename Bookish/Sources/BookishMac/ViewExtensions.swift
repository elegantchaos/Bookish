//
//  ViewExtensions.swift
//  BookishMac
//
//  Created by Sam Deane on 21/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import AppKit

extension NSViewController {
    var application: AppDelegate {
        return NSApp.delegate as! AppDelegate
    }
    
    @objc var safeDocument: Document? {
        get {
            print("safeDocument \(self)")
            if let document = self.view.window?.windowController?.document as? Document {
                return document
            } else if let document = application.documentBeingCreated {
                return document
            } else {
                return nil
            }
        }
    }
    
    @objc var document: Document {
        get {
            if let document = self.view.window?.windowController?.document as? Document {
                return document
            } else if let document = application.documentBeingCreated {
                return document
            }
            
            fatalError("View has no associated document.")
        }
        
    }
}
