// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Cocoa

class CollectionViewController: NSViewController {
    typealias ViewModel = CollectionDocumentViewModel
    
    @objc let cvm: CollectionDocumentViewModel
    
    required init?(coder: NSCoder) {
        self.cvm = Application.sharedInstance.documentWindowControllerFactory.viewModel
        super.init(coder: coder)
        Application.sharedInstance.documentWindowControllerFactory.onFinishedLoading(callback: { (windowController) in
            self.windowDidLoad(windowController)
        })
    }
    
    func windowDidLoad(_ window: CollectionWindowController) {
        
    }
    
    @objc var document: CollectionDocument? {
        get {
            return cvm.document
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        CoreDataTransformers.updateCoreDataBindings(for: self.view, context: cvm.managedObjectContext)
    }
    
  
}

