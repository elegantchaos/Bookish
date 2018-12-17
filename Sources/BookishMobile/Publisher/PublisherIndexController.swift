// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import UIKit
import CoreData
import BookishModel
import Actions

class PublisherIndexController: IndexController<PublisherDetailController, Publisher> {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        application.collectionController.publisherIndexController = self
    }
     
    override func configureCell(_ cell: UITableViewCell, with publisher: Publisher) {
        cell.textLabel!.text = publisher.name
    }
    
}

