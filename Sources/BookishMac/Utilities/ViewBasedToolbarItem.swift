// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

class ViewBasedToolbarItem: NSToolbarItem {
    override func validate() {
        if
            let control = self.view as? NSControl,
            let action = self.action,
            let validator = NSApp.target(forAction: action, to: self.target, from: self) as AnyObject?
        {
            switch validator {
            case let validator as NSUserInterfaceValidations:
                control.isEnabled = validator.validateUserInterfaceItem(self)
            default:
                control.isEnabled = validator.validateToolbarItem(self)
            }
            
        } else {
            super.validate()
        }
    }
}
