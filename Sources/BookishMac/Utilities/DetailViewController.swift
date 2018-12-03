// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

protocol IndexOwner {
    var indexArray: NSArrayController! { get }
}

protocol ManagedObjectTableCell {
    func setup(for view: ManagedObjectViewController, row: Int, item: NSManagedObject)
    func keyView() -> NSView?
}

class ManagedObjectViewController: CollectionViewController, NSTableViewDelegate, NSTableViewDataSource {
    static let unknownViewID = NSUserInterfaceItemIdentifier(rawValue: "unknown")
    
    var rows = [NSManagedObject]()
    var availableRows = IndexSet()
    var keyViewTimer: Timer? = nil
    
    func identifier(for item: NSManagedObject) -> NSUserInterfaceItemIdentifier {
        return ManagedObjectViewController.unknownViewID
    }
    
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
        if let cell = view as? ManagedObjectTableCell {
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
    
    func scheduleRecalculateKeyViews() {
        if let timer = keyViewTimer {
            timer.invalidate()
        }
        
        keyViewTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            self.recalculateKeyViews()
        }
    }
    
    func recalculateKeyViews() {
        //        let rows = availableRows.sorted()
        //        var view: NSView = notesView
        //        for row in rows {
        //            if let rowView = (detailsView.view(atColumn: 0, row: row, makeIfNecessary: false) as? PersonDetailTableCell)?.keyView() {
        //                view.nextKeyView = rowView
        //                view = rowView
        //            }
        //        }
        //        view.nextKeyView = nameView
        //        keyViewTimer = nil
        //    }
    }
}

class DetailViewController<IndexViewController: IndexOwner, Item>: ManagedObjectViewController where IndexViewController: NSViewController {
    weak var indexView: IndexViewController!
    var indexObserver: NSKeyValueObservation?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        indexView = nearestSibling()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if let indexArray = indexView.indexArray {
            indexObserver = indexArray.observe(\NSArrayController.selection, changeHandler: { (index, change) in
                self.selectionChanged()
            })
            selectionChanged()
        }
    }
    
    override func viewWillDisappear() {
        indexObserver = nil
        super.viewWillDisappear()
    }
    
    func selectionChanged() {
        
    }
    
    func selectedItems() -> [Item] {
        if let selection = indexView.indexArray.selectedObjects as? [Item] {
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

// MARK: Table Support
