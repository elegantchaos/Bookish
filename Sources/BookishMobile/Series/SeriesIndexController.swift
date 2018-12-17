// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import UIKit
import CoreData
import BookishModel
import Actions

class SeriesIndexController: IndexController<SeriesDetailController, Series> {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        application.collectionController.seriesIndexController = self
    }

    override func configureCell(_ cell: UITableViewCell, with series: Series) {
        cell.textLabel!.text = series.name
    }
        
}
