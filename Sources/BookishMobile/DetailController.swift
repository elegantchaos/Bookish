// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import CoreData
import BookishModel
import Actions
import Logger

let detailViewChannel = Logger("DetailView")

class DetailController<EntityType>: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var bindings = [Any]()
    @IBOutlet weak var detailView: UITableView!

    override func viewDidLoad() {
        detailViewChannel.debug("view loaded for \(EntityType.self)")
        
        super.viewDidLoad()
        configureView()
    }
    
    func reset() {
        navigationController?.popToRootViewController(animated: false)
        bindings = [Any]()
    }
    
    var representedObject: EntityType? {
        didSet {
            detailViewChannel.debug("represented object changed for \(EntityType.self)")
            configureView()
        }
    }
    
    func configureView() {
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell(style: .default, reuseIdentifier: "Default")
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

}
