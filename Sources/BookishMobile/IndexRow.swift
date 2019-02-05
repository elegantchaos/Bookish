// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel

class IndexRow: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
        
    func configure(for object: ModelObject) {
        titleLabel?.font = application.viewModel.indexFont
        titleLabel?.text = object.value(forKey: "name") as? String
    }
}

