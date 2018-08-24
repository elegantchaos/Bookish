// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import AppKit

protocol CoreDataTransformer {
    var managedObjectContext: NSManagedObjectContext? { get set }
}

struct CoreDataTransformers {
    static let TransformerKey = NSBindingOption(rawValue: "NSValueTransformer")
    static let ObservedObjectKey = NSBindingInfoKey(rawValue: "NSObservedObject")
    static let ObservedPathKey = NSBindingInfoKey(rawValue: "NSObservedKeyPath")
    
    static func updateCoreDataBindings(for view: NSView, context: NSManagedObjectContext) {
        typealias BindingInfo = [NSBindingInfoKey: Any]
        typealias BindingOptions = [NSBindingOption: Any]
        var bindingsToReplace: [(NSView, NSBindingName, BindingInfo, BindingOptions)] = []
        for binding in view.exposedBindings {
            if let info = view.infoForBinding(binding) {
                if let options = info[NSBindingInfoKey(rawValue: "NSOptions")] as? BindingOptions {
                    if let _ = options[self.TransformerKey] as? CoreDataTransformer {
                        bindingsToReplace.append((view, binding, info, options))
                    }
                }
            }
        }
        
        for (view,binding,info,options) in bindingsToReplace {
            let transformer = AuthorsTransformer()
            transformer.managedObjectContext = context
            var newOptions = options
            newOptions[self.TransformerKey] = transformer
            if let path = info[self.ObservedPathKey] as? String, let object = info[self.ObservedObjectKey] {
                view.bind(binding, to:object, withKeyPath:path, options: newOptions)
            }
        }
        
        for child in view.subviews {
            updateCoreDataBindings(for: child, context: context)
        }
    }
}
