// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/01/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import UIKit

class ChooseRoleController: UITableViewController, NSFetchedResultsControllerDelegate {
    let showIdentifiers = false
    
    var row: BookPersonRow? = nil
    var fetcher: NSFetchedResultsController<Role>? = nil
    
    func setup(detailView: BookDetailController, row: BookPersonRow) {
        self.row = row
        fetcher = makeFetcher()
    }
    
    func makeFetcher() -> NSFetchedResultsController<Role> {
        let context = application.collection.managedObjectContext
        let request: NSFetchRequest<Role> = Role.fetcher(in: context)
        request.fetchBatchSize = 20
        request.sortDescriptors = application.viewModel.roleSorting
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: "Role")
        controller.delegate = self
        
        do {
            try controller.performFetch()
//            DispatchQueue.main.async {
//                self.selectIfNecessary()
//            }
            
        } catch {
            let nserror = error as NSError
            indexViewChannel.fatal("couldn't make fetch controller \(nserror), \(nserror.userInfo)")
        }
        
        return controller
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetcher?.sections?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetcher?.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "role", for: indexPath)
        if let item = fetcher?.object(at: indexPath), let name = item.name {
            cell.textLabel?.text = showIdentifiers ? "\(name) (id:\(item.uuid!))" : "\(name)"
            cell.accessoryType = (item == row?.role) ? .checkmark : .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let existingRole = row?.role, let selection = fetcher?.indexPath(forObject: existingRole), selection != indexPath {
            let cell = tableView.cellForRow(at: selection)
            cell?.accessoryType = .none
        }

        if let cell = tableView.cellForRow(at: indexPath), let newRole = fetcher?.object(at: indexPath) {
            cell.accessoryType = .checkmark
            row?.changeRole(to: newRole)
        }
        
        dismiss(animated: true)
    }
//    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        // Return false if you do not want the specified item to be editable.
//        return true
//    }
//
//    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete {
//            let book = fetcher.object(at: indexPath)
//            let info = ActionInfo(sender: tableView)
//            info[ActionContext.selectionKey] = [book]
//            application.actionManager.perform(identifier: "Delete\(entityName)", info: info)
//        }
//    }
    
    
}
