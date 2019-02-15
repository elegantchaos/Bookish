// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Cocoa
import Logger

let collectionViewChannel = Logger("CollectionView")

class CollectionViewController: NSViewController, ViewControllerWithViewModel {
    
    @objc let cvm: CollectionViewState
    
    required init?(coder: NSCoder) {
        self.cvm = Application.sharedInstance.windowControllerFactory.viewModel
        super.init(coder: coder)
    }
    
    init(state: CollectionViewState, nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        self.cvm = state
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    func windowDidLoad(_ window: NSWindowController, storyboard: NSStoryboard) {
        collectionViewChannel.debug("\(self) windowDidLoad")
    }
    
    override func viewDidLoad() {
        collectionViewChannel.debug("\(self) viewDidLoad")
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        collectionViewChannel.debug("\(self) viewWillAppear")
        super.viewWillAppear()
        CoreDataTransformers.updateCoreDataBindings(for: self.view, context: cvm.managedObjectContext)
    }
    
  
}

