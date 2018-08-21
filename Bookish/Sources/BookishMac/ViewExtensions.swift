//
//  ViewExtensions.swift
//  BookishMac
//
//  Created by Sam Deane on 21/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import AppKit

extension NSViewController {
    var document: Document {
        if let document = self.view.window?.windowController?.document as? Document {
            return document
        }
        fatalError("View has no associated document.")
    }
}
