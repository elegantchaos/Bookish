//
//  ViewController.swift
//  Bookish
//
//  Created by Sam Deane on 17/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Cocoa

class CollectionViewController: NSViewController {
    @objc let cvm: CollectionDocumentViewModel
    
    static let TransformerKey = NSBindingOption(rawValue: "NSValueTransformer")
    static let ObservedObjectKey = NSBindingInfoKey(rawValue: "NSObservedObject")
    static let ObservedPathKey = NSBindingInfoKey(rawValue: "NSObservedKeyPath")
    
    required init?(coder: NSCoder) {
        self.cvm = Application.sharedInstance.documentWindowControllerFactory.connectViewModel()
        super.init(coder: coder)
    }
    
    @objc var document: CollectionDocument? {
        get {
            return cvm.document
        }
    }
    
    func updateCoreDataBindings(for view: NSView) {
        typealias BindingInfo = [NSBindingInfoKey: Any]
        typealias BindingOptions = [NSBindingOption: Any]
        var bindingsToReplace: [(NSView, NSBindingName, BindingInfo, BindingOptions)] = []
        for binding in view.exposedBindings {
            if let info = view.infoForBinding(binding) {
                if let options = info[NSBindingInfoKey(rawValue: "NSOptions")] as? BindingOptions {
                    if let _ = options[CollectionViewController.TransformerKey] as? AuthorsTransformer {
                        bindingsToReplace.append((view, binding, info, options))
                    }
                }
            }
        }

        for (view,binding,info,options) in bindingsToReplace {
            let transformer = AuthorsTransformer()
            transformer.managedObjectContext = cvm.managedObjectContext
            var newOptions = options
            newOptions[CollectionViewController.TransformerKey] = transformer
            if let path = info[CollectionViewController.ObservedPathKey] as? String, let object = info[CollectionViewController.ObservedObjectKey] {
                view.bind(binding, to:object, withKeyPath:path, options: newOptions)
            }
        }

        for child in view.subviews {
            updateCoreDataBindings(for: child)
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        updateCoreDataBindings(for: self.view)
    }
}

