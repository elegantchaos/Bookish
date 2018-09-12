// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

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

