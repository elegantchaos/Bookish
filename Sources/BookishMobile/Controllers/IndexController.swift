// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import CoreData
import BookishModel
import Actions
import ActionsKit
import Logger

protocol EntityIndex {
    func select(object: NSManagedObject)
    func reset()
    func reload()
}

let indexViewChannel = Logger("IndexView")

protocol DetailControllerP: AnyObject {
    var representedObject: ModelObject { get set }
}

class IndexController: UITableViewController, EntityIndex, ActionObserver {
    var entityType: ModelObject.Type?
    var modelContext: NSManagedObjectContext?
    lazy var fetcher: NSFetchedResultsController<ModelObject> = makeFetcher()
    
    static let useSectionThreshold = 20
    @IBOutlet var indexTable: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    var detailController: DetailController? {
        if let detailNavigation = splitViewController?.viewControllers.last as? UINavigationController {
            return detailNavigation.topViewController as? DetailController
        }

        return nil
    }
    
    func setup(for entityType: ModelObject.Type, context: NSManagedObjectContext) {
        indexViewChannel.debug("\(entityType) setup")
        self.entityType = entityType
        self.modelContext = context
        self.title = entityType.entityTitle
        reload()
    }
    
    func reset() {
        if let cacheName = entityType?.entityLabel {
            NSFetchedResultsController<ModelObject>.deleteCache(withName: cacheName)
        }
        navigationController?.popToRootViewController(animated: false)
        detailController?.reset()
        modelContext = nil
        fetcher.delegate = nil
    }
    
    func reload() {
        fetcher = makeFetcher()
        fetch(filter: "")
    }
    
    func fetch(filter: String) {
        let predicate = filter.isEmpty ? nil : NSPredicate(format: "name contains[cd] %@", filter)
        fetcher.fetchRequest.predicate = predicate
        
        do {
            NSFetchedResultsController<ModelObject>.deleteCache(withName: entityType!.entityLabel)
            try fetcher.performFetch()
            self.updateAfterFetch()
        } catch let err {
            print(err)
        }
    }
    
    func updateAfterFetch() {
        tableView.reloadData()
        let key: String
        let count = fetcher.fetchedObjects?.count ?? 0
        let label = entityType?.entityLabel ?? ""
        if label.isEmpty {
            key = "index.search.unknown"
        } else {
            key = count > 0 ? "index.search.count" : "index.search.none"
        }
    
        searchBar.placeholder = key.localized(with: ["count" : count, "type": label])
    }
    
    func select(object: NSManagedObject) {
        if let entity = object as? ModelObject {
            if let index = fetcher.indexPath(forObject: entity) {
                indexTable.selectRow(at: index, animated: true, scrollPosition: .middle)
                performSegue(withIdentifier: "showDetail", sender: self)
            }
        }
    }
    
    func selectFirstItemIfNecessary() {
//        if (tableView.indexPathForSelectedRow == nil) && !splitViewController!.isCollapsed {
//            if numberOfSections(in: self.tableView) > 0 {
//                tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .top)
//                performSegue(withIdentifier: "showDetail", sender: self)
//            }
//        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showDetail" {
            return !tableView.isEditing
        } else {
            return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = fetcher.object(at: indexPath)
                if let nav = segue.destination as? UINavigationController, let detail = nav.topViewController as? DetailController {
                    detail.setup(for: object)
                }
            }
        }
    }
    
    // MARK: View Controller
    
    override func viewDidLoad() {
        indexViewChannel.debug("\(entityType!) index didLoad")
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem
        
        let selector = ActionManagerMobile.Responder.performActionSelector
        
        let deleteItem = UIBarButtonItem(title: "Delete", style: .plain, target: nil, action: selector)
        navigationItem.rightBarButtonItems = [editButtonItem, deleteItem]
        fetch(filter: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        indexViewChannel.debug("\(entityType!) index willAppear")
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
   
    override func viewWillDisappear(_ animated: Bool) {
        modelContext = nil
        fetcher.delegate = nil
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetcher.sections?.count ?? 1
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetcher.sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard fetcher.sectionIndexTitles.count > section else { return nil }
        return fetcher.sectionIndexTitle(forSectionName: fetcher.sectionIndexTitles[section])
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetcher.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if tableView == indexTable {
            cell = tableView.dequeueReusableCell(withIdentifier: "item", for: indexPath)
            let item = fetcher.object(at: indexPath)
            (cell as! IndexRow).configure(for: item)
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: "search")
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let book = fetcher.object(at: indexPath)
            let info = ActionInfo(sender: tableView)
            info[ActionContext.selectionKey] = [book]
            application.actionManager.perform(identifier: "Delete\(entityType!)", info: info)
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item1 = UIContextualAction(style: .normal, title: "Foo", handler: { (action, view, handler) in
            print(action)
            handler(true)
        })
        
        let item2 = UIContextualAction(style: .destructive, title: "Bar", handler: { (action, view, handler) in
            print(action)
            handler(true)
        })
        
        return UISwipeActionsConfiguration(actions: [item1,item2])
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item1 = UIContextualAction(style: .normal, title: "Wibble", handler: { (action, view, handler) in
            print(action)
            handler(true)
        })
        
        let item2 = UIContextualAction(style: .destructive, title: "Delete", handler: { (action, view, handler) in
            print(action)
            handler(true)
        })
        
        return UISwipeActionsConfiguration(actions: [item1,item2])
    }
}


extension IndexController: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info.addObserver(self)
        detailController?.provide(context: context)
    }
}


extension IndexController: NSFetchedResultsControllerDelegate {
    func makeFetcher() -> NSFetchedResultsController<ModelObject> {
        guard let context = modelContext, let entityType = entityType else {
            indexViewChannel.fatal("missing context or entity type")
        }
        
        let request = NSFetchRequest<ModelObject>()
        let entityName = String(describing: entityType)
        request.entity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName[entityName]
        request.fetchBatchSize = 20
        request.sortDescriptors = application.viewState.entitySorting[entityName]
        let sectionPath: String?
        if let count = try? context.count(for: request), count > IndexController.useSectionThreshold {
            sectionPath = "sectionName"
        } else {
            sectionPath = nil
        }
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: sectionPath, cacheName: entityType.entityLabel)
        controller.delegate = self
        return controller
    }
    

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let path = newIndexPath {
                tableView.insertRows(at: [path], with: .fade)
                //                tableView.selectRow(at: path, animated: true, scrollPosition: .middle)
            }
            
        case .delete:
            if let path = indexPath {
                tableView.deleteRows(at: [path], with: .fade)
            }
            
        case .update:
            
            if let path = indexPath, let cell = tableView.cellForRow(at: path) as? IndexRow, let object = anObject as? ModelObject {
                cell.configure(for: object)
            }
            
        case .move:
            if let path = indexPath, let newPath = newIndexPath, let cell = tableView.cellForRow(at: path) as? IndexRow, let object = anObject as? ModelObject {
                cell.configure(for: object)
                tableView.moveRow(at: path, to: newPath)
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
}

extension IndexController: UISearchBarDelegate {
     func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        fetch(filter: searchBar.text ?? "")
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        fetch(filter: "")
    }
}

/*
 
 extension BookIndexController: BookChangeObserver {
 func added(relationship: Relationship) {
 }
 
 func removed(relationship: Relationship) {
 }
 
 func added(series: Series) {
 }
 
 func removed(series: Series) {
 }
 
 func added(publisher: Publisher) {
 }
 
 func removed(publisher: Publisher) {
 }
 
 
 func added(books: [Book]) {
 }
 
 func removed(books: [Book]) {
 print("removed")
 }
 }
 
 extension BookIndexController: BookLifecycleObserver {
 func deleted(books: [Book]) {
 
 }
 
 func created(books: [Book]) {
 if let book = books.first, let index = fetcher.indexPath(forObject: book) {
 indexTable.selectRow(at: index, animated: true, scrollPosition: .middle)
 }
 }
 }

 */

