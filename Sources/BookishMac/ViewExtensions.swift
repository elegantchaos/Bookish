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
}
