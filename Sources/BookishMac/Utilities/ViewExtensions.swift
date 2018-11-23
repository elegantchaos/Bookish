// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import ActionsKit

extension NSView {
    
    /**
     Convenience to return the application delegate singleton.
     */
    
    var application: Application {
        return NSApp.delegate as! Application
    }
}

extension NSViewController {
    
    /**
     Convenience to return the application delegate singleton.
     */
    
    var application: Application {
        return NSApp.delegate as! Application
    }

    func nearestChild<T>(excluding: NSViewController? = nil) -> T? where T: NSViewController {
        if let view = self as? T {
            return view
        }
        
        let searchAll = excluding == nil
        for child in children {
            if searchAll || (excluding !== child) {
                if let view: T = child.nearestChild() {
                    return view
                }
            }
        }
        
        return nil
    }
    
    func nearest<T>(excluding: NSViewController? = nil) -> T? where T: NSViewController {
        if let view: T = self.nearestChild(excluding: excluding) {
            return view
        }
        
        if let parent = self.parent {
            return parent.nearest(excluding: self)
        }
        
        return nil
    }
    
    func nearestSibling<T>() -> T? where T: NSViewController {
        return parent?.nearest(excluding: self)
    }
}


extension NSView {
    func appendValidatableItems(to items: inout [NSControl]) {
        let selector = ActionManagerMac.Responder.performActionSelector
        if !isHidden {
            if let viewItem = self as? NSControl, let identifier = viewItem.identifier?.rawValue {
                validationChannel.log("\(identifier)")
                if viewItem.action == selector {
                    items.append(viewItem)
                }
            }
            for subview in subviews {
                subview.appendValidatableItems(to: &items)
            }
        }
    }
    
    func validateButtons() {
        let actionManager = Application.sharedInstance.actionManager
        var items = [NSControl]()
        appendValidatableItems(to: &items)
        for item in items {
            if let button = item as? NSButton, let identifier = item.identifier?.rawValue {
                button.isEnabled = actionManager.validate(identifier: identifier, info: ActionInfo(sender: button))
            }
        }
    }
    
    func scheduleForValidation() {
        OperationQueue.main.addOperation {
            self.validateButtons()
        }
    }
}
