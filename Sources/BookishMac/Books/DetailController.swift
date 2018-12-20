// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import Logger

let detailChannel = Logger("Detail")

class DetailControllerBase: ManagedObjectViewController, ActionContextProvider {
    @objc weak var indexView: IndexControllerBase!
    @objc var index: NSArrayController? {
        return indexView?.indexArray
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

    func rowsForSelection() -> [NSManagedObject] {
        return []
    }
    
    func selectionChanged() {
        detailChannel.debug("selection changed")
        let selectedCount = index?.selectedObjects?.count ?? 0
        let showDetail = selectedCount > 0
        detailsTable.isHidden = !showDetail
        if showDetail {
            updateRows()
        }
        if let wc = view.window?.windowController as? CollectionWindowController {
            wc.validateButtons()
        }
    }
    
    func updateRows() {
        rows = rowsForSelection()
        detailsTable.reloadData()
        
    }
    
    func provideForDetail(context: ActionContext) {
    }
    
    func provide(context: ActionContext) {
        indexView.provideForIndex(context: context)
        provideForDetail(context: context)
    }

    @IBAction func changeImage(_ sender: Any){
        print("change image")
    }

}


class DetailController<EntityKind>: DetailControllerBase {
    let entityName = "\(EntityKind.self)"

    override func awakeFromNib() {
        detailChannel.log("\(entityName) awakened \(self.className)")
        super.awakeFromNib()
        if let iv: IndexController<EntityKind> = nearestSibling() {
            indexView = iv
        }
    }
    

    override func provideForDetail(context: ActionContext) {
        context.info[ActionContext.selectionKey] = selectedItems()
    }
    
    func selectedItems() -> [EntityKind] {
        if let selection = index?.selectedObjects as? [EntityKind] {
            return selection
        }
        
        return []
    }
}
