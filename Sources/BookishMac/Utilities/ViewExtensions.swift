// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import ActionsKit

extension NSResponder {
    
    /**
     Convenience to return the application delegate singleton.
     */
    
    var application: Application {
        return NSApp.delegate as! Application
    }

    /**
     Does the chain from another responder include this one?
    */
    
    func contains(responder: NSResponder?) -> Bool {
        if responder == self {
            return true
        } else if responder == nil {
            return false
        } else {
            return contains(responder: responder?.nextResponder)
        }
    }
}

extension NSViewController {

    /**
     Find the nearest view of the matching type.
     We check the view that the method is called on, then all its children recursively.
    */
    
    func nearestIncludingChildren<T>(excluding: NSViewController? = nil) -> T? where T: NSViewController {
        if let view = self as? T {
            return view
        }
        
        let searchAll = excluding == nil
        for child in children {
            if searchAll || (excluding !== child) {
                if let view: T = child.nearestIncludingChildren() {
                    return view
                }
            }
        }
        
        return nil
    }

    /**
     Find the nearest view of the matching type.
     We check the view that the method is called on, then all its children recursively.
     If that fails, we then move up to the parent, and check all our siblings. We continue
     moving up the parent chain until we find a view, or run out.
     */

    func nearestIncludingParents<T>(excluding: NSViewController? = nil) -> T? where T: NSViewController {
        if let view: T = self.nearestIncludingChildren(excluding: excluding) {
            return view
        }
        
        if let parent = self.parent {
            return parent.nearestIncludingParents(excluding: self)
        }
        
        return nil
    }

    /**
     Find the nearest view of a given type.
     Can return nil if we fail.
    */
    
    func nearestMatchingController<T>() -> T? where T: NSViewController {
        return parent?.nearestIncludingParents(excluding: self)
    }

    /**
     Find the nearest view of a given type.
     We assume that the search will succeed - if not, it's a runtime error.
     */

    func nearestMatchingController<T>() -> T where T: NSViewController {
        let sibling: T? = parent?.nearestIncludingParents(excluding: self)
        return sibling!
    }
}

