// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 30/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

class FetchedResultsTableUpdater: NSObject, NSFetchedResultsControllerDelegate {
    typealias Completion = () -> Void
    
    let table: NSTableView
    var insertions: IndexSet = []
    var deletions: IndexSet = []
    var postInsertion: Completion? = nil
    var postDeletion: Completion? = nil
    var postUpdate: Completion? = nil
    
    init(table: NSTableView) {
        self.table = table
    }
    
//    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        table.beginUpdates()
//    }
//
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
//                let row = indexPath.item
//                table.reloadData(forRowIndexes: [row], columnIndexes: IndexSet(integersIn: 0 ..< table.numberOfColumns))
            }

        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                print("moved \(indexPath) to \(newIndexPath)")
//                table.removeRows(at: [indexPath.item], withAnimation: .effectFade)
//                table.insertRows(at: [newIndexPath.item], withAnimation: .effectFade)
            }

        default:
            break
        }
    }
//
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//
//        if deletions.count > 0 {
//            table.removeRows(at: deletions, withAnimation: .effectFade)
//            postDeletion?()
//            postDeletion = nil
//        }
//
//        if insertions.count > 0 {
//            table.insertRows(at: insertions, withAnimation: .slideDown)
//            insertions.removeAll()
//            postInsertion?()
//            postInsertion = nil
//        }
//
//        table.endUpdates()
//    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        table.reloadData()

        postDeletion?()
        postDeletion = nil
        
        postInsertion?()
        postInsertion = nil
        
        postUpdate?()
    }
}
