// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

class CollectionIndexViewController: NSTabViewController {
    typealias ViewModel = CollectionDocumentViewModel
    @IBOutlet weak var detailView: CollectionDetailViewController?
    @objc let cvm: CollectionDocumentViewModel
    
    required init?(coder: NSCoder) {
        self.cvm = Application.sharedInstance.documentWindowControllerFactory.viewModel
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        detailView = nearestSibling()
    }
 
}
