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
    }
    
    let items = [
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "item") as! RootRow
        let item = items[indexPath.row]
        cell.setup(for: item)
        return cell
    }
 
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        collapseDetailViewController = false
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
