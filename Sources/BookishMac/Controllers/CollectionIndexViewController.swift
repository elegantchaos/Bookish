// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel
import Actions

class CollectionIndexViewController: NSTabViewController {
    @objc let cvm: CollectionViewState
    
    lazy var detailView: DetailController = nearestMatchingController()
    
    required init?(coder: NSCoder) {
        self.cvm = Application.sharedInstance.windowControllerFactory.viewModel
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        let entities = BookishModel.topLevelEntities
        for n in 0 ..< entities.count {
            let entity = entities[n]
            if let controller = tabViewItems[n].viewController as? IndexController {
                controller.setup(for: entity)
            }
        }
        
        super.viewDidLoad()
    }
}

extension CollectionIndexViewController: ActionContextProvider {
    func provide(context: ActionContext) {
        detailView.addContextForDetail(context: context)
    }
}
