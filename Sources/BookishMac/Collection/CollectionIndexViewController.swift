// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel
import Actions

class CollectionIndexViewController: NSTabViewController, ViewControllerWithViewModel {
    @objc let cvm: CollectionViewState
    
    let entities = [ Book.self, Person.self, Publisher.self, Series.self ]
    
    lazy var detailView: GenericDetailController = nearestMatchingController()

    required init?(coder: NSCoder) {
        self.cvm = Application.sharedInstance.windowControllerFactory.viewModel
        super.init(coder: coder)
    }
    
    func windowDidLoad(_ window: NSWindowController) {
        if let window = window as? CollectionWindowController {
            for n in 0 ..< entities.count {
                let entity = entities[n]
                if let controller = tabViewItems[n].viewController as? GenericIndexController {
                    controller.loadView()
                    controller.setup(for: entity, window: window)
                }
            }
        }
    }
}

extension CollectionIndexViewController: ActionContextProvider {
    func provide(context: ActionContext) {
        detailView.addContextForDetail(context: context)
    }
}
