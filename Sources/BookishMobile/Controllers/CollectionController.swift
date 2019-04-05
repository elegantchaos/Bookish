// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel

class CollectionController: UITableViewController {
    var collapseDetailViewController: Bool = true
    var detailNav: UINavigationController!
    var indexNav: UINavigationController!
    
    struct Item {
        let entity: ModelObject.Type?
        let identifier: String
        
        init(entity: ModelObject.Type? = nil, identifier: String = "item") {
            self.entity = entity
            self.identifier = identifier
        }
    }
    
    var items = BookishModel.topLevelEntities.map { Item(entity: $0) }

    func reset(mode: CollectionContainer.PopulateMode) {
        if let detailView = detailNav.topViewController as? DetailController {
            detailView.reset()
        }
        indexNav.popToRootViewController(animated: false)
        detailNav.popToRootViewController(animated: false)
        let application = self.application
        application.collection.delete(remove: false)
        DispatchQueue.main.async {
            application.collection = application.setupCollection(mode: mode)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        items.append(Item(identifier: "intro"))

        if let splitView = splitViewController {
            splitView.delegate = self
            splitView.preferredDisplayMode = .allVisible
            indexNav = splitView.viewControllers.first as? UINavigationController
            detailNav = splitView.viewControllers.last as? UINavigationController
        }
        self.splitViewController?.delegate = self
        application.collectionController = self
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        print(traitCollection)
        super.traitCollectionDidChange(previousTraitCollection)
    }
}

extension CollectionController: UISplitViewControllerDelegate {

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
//        guard let nav = primaryViewController as? UINavigationController, let controller = nav.topViewController as? CollectionController else {
//            return true
//        }
//
//        return controller.collapseDetailViewController
        
        print("collapsing")
        
        let shouldSkipDefaultBehaviour = true
        
        return shouldSkipDefaultBehaviour
    }
}
