// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit

class RootRow: UITableViewCell {
    
    var item: RootController.Item?
    
    func setup(for item: RootController.Item) {
        self.item = item
    }
}

class RootCategoryRow: RootRow {
    @IBOutlet weak var itemLabel: UILabel!
    @IBOutlet weak var itemImage: UIImageView!
    
    override func setup(for item: RootController.Item) {
        super.setup(for: item)
        itemLabel.text = item.name
        itemImage.image = UIImage(named: "\(item.entity)Placeholder")
    }
}

class RootIntroRow: RootRow {
}
