// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel

class CollectionIndexViewController: NSTabViewController {
    @objc let cvm: CollectionViewState
    
    let entities = [ Book.self, Person.self, Publisher.self, Series.self ]
    
    required init?(coder: NSCoder) {
        self.cvm = Application.sharedInstance.windowControllerFactory.viewModel
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for n in 0 ..< entities.count {
            let entity = entities[n]
            if let controller = tabViewItems[n].viewController as? GenericIndexController {
                controller.setup(for: entity)
            }
        }
    }

    lazy var detailView: CollectionDetailViewController = nearestMatchingController()
 
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        print("blah")
    }
}
