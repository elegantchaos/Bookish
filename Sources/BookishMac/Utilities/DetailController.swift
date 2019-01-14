// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import Logger
import BookishModel

let detailChannel = Logger("Detail")

protocol DetailTableCell {
    func setup(for view: DetailControllerBase, row: Int, item: NSManagedObject)
    func keyView() -> NSView?
}

/**
 Table support, bindings, and IBActions have to live in a base class,
 as they can't go into a Swift generic class.
 */

class DetailControllerBase: CollectionViewController {
    static let unknownViewID = NSUserInterfaceItemIdentifier(rawValue: "unknown")

    @IBOutlet weak var nameView: NSTextField!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var lastFixedKeyView: NSControl!
    @IBOutlet weak var detailsTable: NSTableView!
    @objc var index: NSArrayController?
   
    var rows = [NSManagedObject]()
    var availableRows = IndexSet()
    var keyViewTimer: Timer? = nil

    func identifier(for item: NSManagedObject) -> NSUserInterfaceItemIdentifier {
        return DetailControllerBase.unknownViewID
    }
    
    func scheduleRecalculateKeyViews() {
        if let timer = keyViewTimer {
            timer.invalidate()
        }
        
        keyViewTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            self.recalculateKeyViews()
        }
    }
    
    func recalculateKeyViews() {
        let rows = availableRows.sorted()
        var view: NSView = lastFixedKeyView
        for row in rows {
            if let rowView = (detailsTable.view(atColumn: 0, row: row, makeIfNecessary: false) as? DetailTableCell)?.keyView() {
                view.nextKeyView = rowView
                view = rowView
            }
        }
        view.nextKeyView = nameView
        keyViewTimer = nil
    }

    @IBAction func changeImage(_ sender: Any){
        print("change image")
    }
    
}

// MARK: Table Support

extension DetailControllerBase: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return rows.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < rows.count else {
            return nil
        }
        
        let item = rows[row]
        let viewID = identifier(for: item)
        let view = tableView.makeView(withIdentifier: viewID, owner: self)
        if let cell = view as? DetailTableCell {
            cell.setup(for: self, row: row, item: item)
        }
        
        return view
    }
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        availableRows.insert(row)
        scheduleRecalculateKeyViews()
    }
    
    func tableView(_ tableView: NSTableView, didRemove rowView: NSTableRowView, forRow row: Int) {
        availableRows.remove(row)
        scheduleRecalculateKeyViews()
    }
    
}

// MARK: Generic Detail Controller

class DetailController<EntityKind>: DetailControllerBase {
    weak var indexView: IndexController<EntityKind>!
    let entityName = "\(EntityKind.self)"

    override func awakeFromNib() {
        detailChannel.log("\(entityName) awakened \(self.className)")
        super.awakeFromNib()
        if let iv: IndexController<EntityKind> = nearestSibling() {
            indexView = iv
            index = indexView.indexArray
        }
    }
   
    func provideForDetail(context: ActionContext) {
        context.info[ActionContext.selectionKey] = selectedItems()
    }
    
    func selectedItems() -> [EntityKind] {
        if let selection = index?.selectedObjects as? [EntityKind] {
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
    
    func detailItemsForSelection() -> [NSManagedObject] {
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
        
        if selectedCount == 1 {
            if let item = indexView.indexArray.selectedObjects[0] as? ModelObject {
                if let data = item.value(forKey: "image") as? Data, let image = NSImage(data: data) {
                    imageView.image = image
                } else {
                    let placeholderName = "\(entityName)Placeholder"
                    if let image = NSImage(named: placeholderName) {
                        imageView.image = image
                        if let urlString = item.value(forKey: "imageURL") as? String, let url = URL(string: urlString) {
                            application.imageCache.image(for: url) { (image) in
                                self.imageView.image = image
                            }
                        }
                    }
                }
            }
        }

    }
    
    func updateRows() {
        rows = detailItemsForSelection()
        detailsTable.reloadData()
        
    }
    
}

extension DetailController: ActionContextProvider {
    func provide(context: ActionContext) {
        indexView.provideForIndex(context: context)
        provideForDetail(context: context)
    }
}
