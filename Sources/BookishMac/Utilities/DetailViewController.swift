// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions

protocol IndexOwner {
    var indexArray: NSArrayController! { get }
    func provideIndexInfo(context: ActionContext)
}

class DetailViewController<IndexViewController: IndexOwner, Item>: ManagedObjectViewController where IndexViewController: NSViewController {
    weak var indexView: IndexViewController!
    var indexObserver: NSKeyValueObservation?
    
    @objc var index: NSArrayController? {
        return indexView?.indexArray
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        indexView = nearestSibling()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if let index = index {
            indexObserver = index.observe(\NSArrayController.selection, changeHandler: { (index, change) in
                self.selectionChanged()
            })
            selectionChanged()
        }
    }
    
    override func viewWillDisappear() {
        indexObserver = nil
        super.viewWillDisappear()
    }
    
    func rowsForSelection() -> [NSManagedObject] {
        return []
    }
    
    func selectionChanged() {
        let selectedCount = index?.selectedObjects?.count ?? 0
        let showDetail = selectedCount > 0
        detailsTable.isHidden = !showDetail
        if showDetail {
            updateRoles()
        }
        if let wc = view.window?.windowController as? CollectionWindowController {
            wc.validateButtons()
        }
    }
    
    func updateRoles() {
        rows = rowsForSelection()
        detailsTable.reloadData()
        
    }
    
    func selectedItems() -> [Item] {
        if let selection = index?.selectedObjects as? [Item] {
            return selection
        }
        
        return []
    }
    
    func items<Container, Item>(in selection: [Container], property: String) -> (Set<Item>, Set<Item>) where Container: NSManagedObject {
        var all = Set<Item>()
        var common = Set<Item>()
        for container in selection {
            if let items = container.value(forKey: property) as? Set<Item> {
                if all.count == 0 {
                    common.formUnion(items)
                } else {
                    common.formIntersection(items)
                }
                all.formUnion(items)
            }
        }
        return (all, common)
    }
}

// MARK: Action Support

extension DetailViewController: ActionContextProvider {
    func provideDetailInfo(context: ActionContext) {
        context.info[ActionContext.selectionKey] = selectedItems()
    }
    
    func provide(context: ActionContext) {
        if let indexView = indexView {
            indexView.provideIndexInfo(context: context)
        }
        provideDetailInfo(context: context)
    }
}


