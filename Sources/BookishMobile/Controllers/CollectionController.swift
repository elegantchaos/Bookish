// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel

class CollectionController: UITableViewController {
    var collapseDetailViewController: Bool = true

    struct Item {
        let entity: ModelObject.Type?
        let identifier: String
        
        init(entity: ModelObject.Type? = nil, identifier: String = "item") {
            self.entity = entity
            self.identifier = identifier
        }
    }
    
    let items = [
        Item(entity: Book.self),
        Item(entity: Person.self),
        Item(entity: Publisher.self),
        Item(entity: Series.self),
        Item(identifier: "intro"),
        ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.splitViewController?.delegate = self
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: item.identifier) as! RootRow
        cell.setup(for: item)
        return cell
    }
 
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        collapseDetailViewController = false
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showIndex" {
            if let controller = segue.destination as? IndexController, let row = sender as? RootRow, let item = row.item, let entity = item.entity {
                controller.setup(for: entity, context: application.collection.managedObjectContext)
            }
        }
    }
}

extension CollectionController: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        guard let nav = primaryViewController as? UINavigationController, let controller = nav.topViewController as? CollectionController else {
            return true
        }
        
        return controller.collapseDetailViewController
    }
}
