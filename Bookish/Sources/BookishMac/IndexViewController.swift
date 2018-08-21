//
//  IndexViewController.swift
//  BookishMac
//
//  Created by Sam Deane on 21/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Cocoa
import BookishModel

class IndexViewController: NSViewController, NSFetchedResultsControllerDelegate, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet weak var tableView: NSTableView!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }
    
    @IBAction func insertEdition(_ sender: Any) {
        let context = self.fetchedResultsController.managedObjectContext
        let newEvent = Edition(context: context)
        
        // If appropriate, configure the new managed object.
        let date = Date()
        newEvent.name = "\(date)"
        
        // Save the context.
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let id = NSUserInterfaceItemIdentifier("Edition")
        if let view = tableView.makeView(withIdentifier: id, owner: self) {
            return view
        }
        return nil
    }
    
    var fetchedResultsController: NSFetchedResultsController<Edition> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Edition> = Edition.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let context = self.document.managedObjectContext!
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return _fetchedResultsController!
    }
 
    var _fetchedResultsController: NSFetchedResultsController<Edition>? = nil

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
//        switch type {
//        case .insert:
//            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
//        case .delete:
//            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
//        default:
//            return
//        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//        switch type {
//        case .insert:
//            tableView.insertRows(at: [newIndexPath!], withAnimation: .fade)
//        case .delete:
//            tableView.deleteRows(at: [indexPath!], with: .fade)
//        case .update:
//            configureCell(tableView.cellForRow(at: indexPath!)!, withEdition: anObject as! Edition)
//        case .move:
//            configureCell(tableView.cellForRow(at: indexPath!)!, withEdition: anObject as! Edition)
//            tableView.moveRow(at: indexPath!, to: newIndexPath!)
//        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
