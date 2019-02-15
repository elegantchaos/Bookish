// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel

class CollectionIndexViewController: NSTabViewController, ViewControllerWithViewModel {
    typealias ViewModel = CollectionViewState
    
    @objc let cvm: CollectionViewState
    
    let entities = [ Book.self, Person.self, Publisher.self, Series.self ]
    
    required init?(coder: NSCoder) {
        self.cvm = Application.sharedInstance.windowControllerFactory.viewModel
        super.init(coder: coder)
    }
    
    func windowDidLoad(_ window: CollectionWindowController) {
        for n in 0 ..< entities.count {
            let entity = entities[n]
            if let controller = tabViewItems[n].viewController as? GenericIndexController {
                controller.setup(for: entity, window: window)
            }
        }
    }
    

    lazy var detailView: CollectionDetailViewController = nearestMatchingController()
}
