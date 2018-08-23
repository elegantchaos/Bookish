//
//  ViewExtensions.swift
//  BookishMac
//
//  Created by Sam Deane on 21/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import AppKit

extension NSViewController {
    
    /**
     Convenience to return the application delegate singleton.
     */
    
    var application: Application {
        return NSApp.delegate as! Application
    }
    
    @objc var document: CollectionDocument? {
        get {
            if let document = self.view.window?.windowController?.document as? CollectionDocument {
                return document
            } else if let document = (application.documentBeingCreated as? CollectionDocumentViewModel)?.document {
                return document
            } else {
                return nil
            }
        }
        
    }
}
