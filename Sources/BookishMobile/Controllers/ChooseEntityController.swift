// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 30/01/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel

protocol ChooseItemTarget {
    associatedtype EntityType: ModelObject
    
    var value: EntityType? { get }
    func choose(value: EntityType)
}

class ChooseEntityController<ItemTarget: ChooseItemTarget>: UITableViewController, NSFetchedResultsControllerDelegate {
    let showIdentifiers = false
    
    typealias EntityType = ItemTarget.EntityType
    var target: ItemTarget!
    var collection: SyncedCollection! // TODO: do we need to store this?
    var fetcher: NSFetchedResultsController<EntityType>!
    
    func setup(target: ItemTarget, sort: [NSSortDescriptor], collection: SyncedCollection) {
        self.target = target
        self.collection = collection
        self.fetcher = makeFetcher(sort: sort)
    }
    
    func makeFetcher(sort: [NSSortDescriptor]) -> NSFetchedResultsController<EntityType> {
        let context = collection.managedObjectContext
        let request: NSFetchRequest<EntityType> = EntityType.fetcher(in: context)
        request.fetchBatchSize = 20
        request.sortDescriptors = sort
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "item", for: indexPath)
        if let item = fetcher?.object(at: indexPath), let name = item.value(forKey: "name"), let id = item.value(forKey: "uuid") {
            cell.textLabel?.text = showIdentifiers ? "\(name) (id:\(id))" : "\(name)"
            cell.accessoryType = (item == target?.value) ? .checkmark : .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let existingValue = target.value, let selection = fetcher.indexPath(forObject: existingValue), selection != indexPath {
            let cell = tableView.cellForRow(at: selection)
            cell?.accessoryType = .none
        }
        
        if let cell = tableView.cellForRow(at: indexPath), let newValue = fetcher?.object(at: indexPath) {
            cell.accessoryType = .checkmark
            target.choose(value: newValue)
        }
        
        dismiss(animated: true)
    }

}
