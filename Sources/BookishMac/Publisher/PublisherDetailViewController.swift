// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel
import Dispatch

class PublisherDetailViewController: DetailViewController<PublisherIndexViewController, Publisher> {
    @IBOutlet weak var nameView: NSTextField!
    @IBOutlet weak var notesView: NSTextField!
    @IBOutlet weak var detailsView: NSTableView!
    
    static let bookViewID = NSUserInterfaceItemIdentifier(rawValue: "book")

    
//    public func items<Container, Item>(in selection: [Container], property: KeyPath<Container, Any>) -> (Set<Item>, Set<Item>) {
//        var all = Set<Item>()
//        var common = Set<Item>()
//        for container in selection {
//            if let books = container[keyPath: property] as? Set<Item> {
//                if all.count == 0 {
//                    common.formUnion(books)
//                } else {
//                    common.formIntersection(books)
//                }
//                all.formUnion(books)
//            }
//        }
//        return (all, common)
//    }

    func rowsForSelection() -> [NSManagedObject] {
        let selected: [Publisher] = selectedItems()
        let (_, common): (Set<Book>, Set<Book>) = items(in: selected, property: "books")
        return common.sorted(by: { $0.name ?? "" < $1.name ?? ""})
    }
    
    override func selectionChanged() {
        let selectedCount = indexView.indexArray.selectedObjects?.count ?? 0
        let showDetail = selectedCount > 0
        detailsView.isHidden = !showDetail
        if showDetail {
            updateRoles()
        }
        if let wc = view.window?.windowController as? CollectionWindowController {
            wc.validateButtons()
        }
    }
    
    func updateRoles() {
        rows = rowsForSelection()
        detailsView.reloadData()
        
    }
    
    override func identifier(for item: NSManagedObject) -> NSUserInterfaceItemIdentifier {
        switch item {
        case is Book:
            return PublisherDetailViewController.bookViewID
        default:
            return super.identifier(for: item)
        }
    }
}

// MARK: Actions

extension PublisherDetailViewController: ActionContextProvider {
    func provideDetailInfo(context: ActionContext) {
        if let selection = indexView.indexArray.selectedObjects as? [Person] {
            context.info[ActionContext.selectionKey] = selection
        }
    }
    
    func provide(context: ActionContext) {
        indexView.provideIndexInfo(context: context)
        provideDetailInfo(context: context)
    }
}
