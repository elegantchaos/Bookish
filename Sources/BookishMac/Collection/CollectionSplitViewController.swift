// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Cocoa

class CollectionSplitViewController: NSSplitViewController {
    let initialWidth: CGFloat = 256.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitView.setPosition(initialWidth, ofDividerAt: 0)
    }
    
}
