// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit

class RootController: UITableViewController {
    var collapseDetailViewController: Bool = true

    struct Item {
        let name: String
        let entity: String
        let identifier: String
        
        init(name: String = "", entity: String = "", identifier: String = "item") {
            self.name = name
            self.entity = entity
            self.identifier = identifier
        }
    }
    
    let items = [
        Item(identifier: "intro"),
        Item(name: "Books", entity: "Book"),
        Item(name: "People", entity: "Person"),
        Item(name: "Publishers", entity: "Publisher"),
        Item(name: "Series", entity: "Series")
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
            if let controller = segue.destination as? IndexControllerX, let row = sender as? RootRow, let item = row.item {
                controller.setup(for: item.entity, context: application.collection.managedObjectContext)
            }
        }
    }
}

extension RootController: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        guard let nav = primaryViewController as? UINavigationController, let controller = nav.topViewController as? RootController else {
            return true
        }
        
        return controller.collapseDetailViewController
    }
}
