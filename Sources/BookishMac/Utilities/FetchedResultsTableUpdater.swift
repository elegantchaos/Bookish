// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 30/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

class FetchedResultsTableUpdater: NSObject, NSFetchedResultsControllerDelegate {
    typealias Completion = () -> Void
    
    let justUpdate = false
    let table: NSTableView
    var insertions: IndexSet = []
    var deletions: IndexSet = []
    var updates: IndexSet = []
    var postInsertion: Completion? = nil
    var postDeletion: Completion? = nil
    var postUpdate: Completion? = nil
    
    init(table: NSTableView) {
        self.table = table
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertions.removeAll()
        deletions.removeAll()
        updates.removeAll()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let path = newIndexPath {
                print("inserted \(path)")
                insertions.insert(path.item)
            }

        case .delete:
            if let path = indexPath {
                print("deleted \(path)")
                deletions.insert(path.item)
            }

        case .update:
            if let path = indexPath {
                print("updated \(path)")
                updates.insert(path.item)
            }

        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                print("moved \(indexPath) to \(newIndexPath)")
                deletions.insert(indexPath.item)
                insertions.insert(newIndexPath.item)
            }

        default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        if justUpdate {
            table.reloadData()

            postDeletion?()
            postDeletion = nil
            
            postInsertion?()
            postInsertion = nil
            
            postUpdate?()
        } else {
            table.beginUpdates()
                    if deletions.count > 0 {
                        table.removeRows(at: deletions, withAnimation: .effectFade)
                        postDeletion?()
                        postDeletion = nil
                    }

                    if insertions.count > 0 {
                        table.insertRows(at: insertions, withAnimation: .slideDown)
                        insertions.removeAll()
                        postInsertion?()
                        postInsertion = nil
                    }
            
            if updates.count > 0 {
                let columns = IndexSet(integersIn: 0 ..< table.numberOfColumns)
                table.reloadData(forRowIndexes: updates, columnIndexes: columns)
            }
            
            table.endUpdates()
            postUpdate?()
            
        }
    }
}
