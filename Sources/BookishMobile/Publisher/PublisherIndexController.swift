// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import UIKit

class PublisherIndexController: IndexController<PublisherDetailController, Publisher> {
     
    override func configureCell(_ cell: UITableViewCell, with publisher: Publisher) {
        cell.textLabel!.text = publisher.name
    }
    
}

