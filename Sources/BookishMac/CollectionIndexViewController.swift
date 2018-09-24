// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

class CollectionIndexViewController: NSTabViewController {
    @IBOutlet weak var detailView: CollectionDetailViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        detailView = nearestSibling()
    }
    
    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)
        if let detailView = self.detailView, let item = tabViewItem {
            let detailTabs = detailView.tabView
            let index = tabView.indexOfTabViewItem(item)
            let tab = detailTabs.tabViewItem(at: index)
            detailView.tabView.selectTabViewItem(tab)
        }
    }
}
