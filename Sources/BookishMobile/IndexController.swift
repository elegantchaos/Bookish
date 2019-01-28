// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import CoreData
import BookishModel
import Actions
import Logger

protocol EntityIndex {
    func select(object: NSManagedObject)
    func reset()
    func reload()
}

let indexViewChannel = Logger("IndexView")

class IndexController<DetailControllerType: DetailController<EntityType>, EntityType: ModelObject>: UITableViewController, NSFetchedResultsControllerDelegate, ActionContextProvider, EntityIndex {
    var entityName = "\(EntityType.self)"
    var modelContext: NSManagedObjectContext? = nil
    lazy var fetcher: NSFetchedResultsController<EntityType> = makeFetcher()
    
    @IBOutlet var indexTable: UITableView!

    var detailController: DetailControllerType? {
        if let split = splitViewController {
            let controllers = split.viewControllers
            return (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailControllerType
        }

        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        modelContext = application.collection.managedObjectContext
        application.collectionController.indexControllers[entityName] = self
        
        navigationItem.rightBarButtonItem = editButtonItem
    }

    func reset() {
        NSFetchedResultsController<EntityType>.deleteCache(withName: entityName)
        navigationController?.popToRootViewController(animated: false)
        detailController?.reset()
        modelContext = nil
        fetcher.delegate = nil
    }
    
    func reload() {
        modelContext = application.collection.managedObjectContext
        fetcher = makeFetcher()
        indexTable.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    func select(object: NSManagedObject) {
        if let entity = object as? EntityType {
            if let index = fetcher.indexPath(forObject: entity) {
                indexTable.selectRow(at: index, animated: true, scrollPosition: .bottom)
                performSegue(withIdentifier: "showDetail", sender: self)
            }
        }
    }
  
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = fetcher.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailControllerType
                controller.representedObject = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = fetcher.object(at: indexPath)
        configureCell(cell, with: item)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let book = fetcher.object(at: indexPath)
            let info = ActionInfo(sender: tableView)
            info[ActionContext.selectionKey] = [book]
            application.actionManager.perform(identifier: "Delete\(entityName)", info: info)
        }
    }


    func makeFetcher() -> NSFetchedResultsController<EntityType> {
        guard let context = modelContext else {
            indexViewChannel.fatal("missing context")
        }
        
        let request: NSFetchRequest<EntityType> = EntityType.fetcher(in: context)
        request.fetchBatchSize = 20
        request.sortDescriptors = application.viewModel.bookIndexSorting
        
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "sectionName", cacheName: entityName)
        controller.delegate = self
        
        do {
            try controller.performFetch()
            DispatchQueue.main.async {
                self.selectIfNecessary()
            }
            
        } catch {
            let nserror = error as NSError
            indexViewChannel.fatal("couldn't make fetch controller \(nserror), \(nserror.userInfo)")
        }
        
        return controller
    }
    
    func selectIfNecessary() {
        if (tableView.indexPathForSelectedRow == nil) && !splitViewController!.isCollapsed {
            if self.numberOfSections(in: self.tableView) > 0 {
                self.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .top)
                self.performSegue(withIdentifier: "showDetail", sender: self)
            }
        }
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
    
    func configureCell(_ cell: UITableViewCell, with object: EntityType) {
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let path = newIndexPath {
                tableView.insertRows(at: [path], with: .fade)
            }
            
        case .delete:
            if let path = indexPath {
                tableView.deleteRows(at: [path], with: .fade)
            }
            
        case .update:
            
            if let path = indexPath, let cell = tableView.cellForRow(at: path), let object = anObject as? EntityType {
                configureCell(cell, with: object)
            }
            
        case .move:
            if let path = indexPath, let newPath = newIndexPath, let cell = tableView.cellForRow(at: path), let object = anObject as? EntityType {
                configureCell(cell, with: object)
                tableView.moveRow(at: path, to: newPath)
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
     // In the simplest, most efficient, case, reload the table view.
     tableView.reloadData()
     }
     */
    

    func provide(context: ActionContext) {
        detailController?.provide(context: context)
    }
    
}
