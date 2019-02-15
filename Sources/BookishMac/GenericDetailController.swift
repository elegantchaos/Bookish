// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


import AppKit
import Actions
import Logger
import BookishModel

let detailChannel = Logger("Detail")

protocol KeyableTableCell {
    func keyView() -> NSView?
}

protocol DetailTableCell: KeyableTableCell {
    func setup(for row: DetailItem, of view: GenericDetailController)
}

/**
 Table support, bindings, and IBActions have to live in a base class,
 as they can't go into a Swift generic class.
 */

class GenericDetailController: CollectionViewController {
    static let unknownViewID = NSUserInterfaceItemIdentifier(rawValue: "unknown")
    
    @IBOutlet weak var nameView: NSTextField!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var lastFixedKeyView: NSControl!
    @IBOutlet weak var detailsTable: NSTableView!
    @IBOutlet weak var subtitleView: NSTextField!
    @IBOutlet weak var controlColumn: NSTableColumn!
    @IBOutlet weak var editButton: NSButton!
    @IBOutlet weak var personList: NSArrayController!
    @IBOutlet weak var publisherList: NSArrayController!
    @IBOutlet weak var seriesList: NSArrayController!
    @IBOutlet weak var roleList: NSArrayController!
    
    var entityName: String = ""
    @objc var index: NSArrayController!
    var source = DetailProvider()
    var editing = false
    
    internal lazy var indexView: GenericIndexController = nearestMatchingController()
    
//    @objc var index: NSArrayController {
//        return indexView.indexArray!
//    }
    
   var rows = [NSManagedObject]()
    var availableRows = 0
    var keyViewTimer: Timer? = nil
    
    func setup(for index: GenericIndexController, type entityType: ModelObject.Type) {
        detailChannel.debug("setup for \(entityType)")
        indexView = index
        self.index = index.indexArray
        entityName = String(describing: entityType)
        source = entityType.getProvider()
        selectionChanged()
    }
    
    func identifier(for item: NSManagedObject) -> NSUserInterfaceItemIdentifier {
        return GenericDetailController.unknownViewID
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
        var view: NSView = lastFixedKeyView
        for row in 0 ..< availableRows {
            for column in 0 ..< detailsTable.numberOfColumns {
                if let rowView = (detailsTable.view(atColumn: column, row: row, makeIfNecessary: false) as? KeyableTableCell)?.keyView() {
                    view.nextKeyView = rowView
                    view = rowView
                }
            }
        }
        view.nextKeyView = nameView
        keyViewTimer = nil
    }
    
    @IBAction func changeImage(_ sender: Any){
        print("change image")
    }
    
    
    fileprivate func connectIndexView() -> GenericIndexController {
        let iv: GenericIndexController? = nearestMatchingController()
        return iv!
    }
    
    func addContextForDetail(context: ActionContext) {
        context.info[ActionContext.selectionKey] = index?.selectedObjects
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
        if showDetail, let object = index.selection as? NSObject {
            updateRows()
            
            if let path = source.titleProperty {
                nameView.objectValue = object.value(forKey: path)
            }
            
            if let path = source.subtitleProperty, let value = object.value(forKey: path) as? String, source.isEditing || !value.isEmpty {
                subtitleView.objectValue = value
                subtitleView.isHidden = false
            } else {
                subtitleView.isHidden = true
            }

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
    
    func calculateRows() {
        let selection = index?.selectedObjects as? [ModelObject] ?? []
        source.filter(for: selection, editing: editing, context: cvm)
    }

    func updateRows() {
        detailChannel.debug("updating people list")
        
        calculateRows()
        detailsTable.reloadData()
    }
    func person(at index: Int) -> Person? {
        if let people = personList.arrangedObjects as? [Person], index != -1 {
            return people[index]
        }
        
        return nil
    }
    
    func index(of person: Person) -> Int? {
        if let people = personList.arrangedObjects as? [Person] {
            return people.firstIndex(of: person)
        }
        
        return nil
    }
    
    func publisher(at index: Int) -> Publisher? {
        if let publishers = publisherList.arrangedObjects as? [Publisher], index != -1 {
            return publishers[index]
        }
        
        return nil
    }
    
    func index(of publisher: Publisher) -> Int? {
        if let publishers = publisherList.arrangedObjects as? [Publisher] {
            return publishers.firstIndex(of: publisher)
        }
        
        return nil
    }
}

// MARK: Table Support

extension GenericDetailController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return source.itemCount(for: 0)
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let columnID = tableColumn?.identifier else { return nil }
        
        let rowInfo = source.info(section: 0, row: row)
        let viewID = NSUserInterfaceItemIdentifier(rawValue: rowInfo.viewID(for: columnID.rawValue))
        
        guard let view = tableView.makeView(withIdentifier: viewID, owner: self) else { return nil }
        if let cell = view as? DetailTableCell {
            cell.setup(for: rowInfo, of: self)
        }
        view.scheduleForValidation()
        
        return view
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        AnnotatedTableCellView.updateSelection(tableView: tableView, row: row)
        return true
    }

    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        availableRows += 1
        scheduleRecalculateKeyViews()
    }
    
    func tableView(_ tableView: NSTableView, didRemove rowView: NSTableRowView, forRow row: Int) {
        availableRows -= 1
        scheduleRecalculateKeyViews()
    }
}

// MARK: Generic Detail Controller


extension GenericDetailController: ActionContextProvider {
    func provide(context: ActionContext) {
        indexView.addContextForIndex(context: context)
        addContextForDetail(context: context)
    }
}

// MARK: EditableView Support

extension GenericDetailController: EditableView {
    var isEditing: Bool { return editing }
    
    func setEditing(_ value: Bool) {
        editing = value
    }
    
    func willToggleEditing() {
        // change focus; this will commit any editing changes that were
        // in progress if we're turning editing off
        // NB need to do this before changing the editing flag, so that the
        // context is correct when any editing-related actions fire
        let newResponder: NSResponder = editing ? nameView : indexView
        view.window?.makeFirstResponder(newResponder)
    }
    
    func didToggleEditing() {
        // rebuild the view on the next cycle, to give editing
        // changes a chance to get properly committed first
        DispatchQueue.main.async {
            self.adjustControlsForEditing()
            self.selectionChanged()
        }
    }
    
    func adjustControlsForEditing() {
        controlColumn.isHidden = !editing
        //        editButton.title = editing ? "Done" : "Edit"
        detailChannel.debug(editing ? "enabled editing" : "disabled editing")
    }
}

// MARK: Local IBActions

extension GenericDetailController {
    
}


// MARK: Action Support

//extension GenericDetailController: BookChangeObserver {
//
//
//    func detailRow(for context: ActionContext) -> Int {
//        var row = -1
//        if let view = context.sender as? NSView {
//            row = detailsTable.row(for: view)
//        }
//
//        if row < 0, let view = view.window?.firstResponder as? NSView {
//            row = detailsTable.row(for: view)
//        }
//
//        return row
//    }
//
//
//    func added(relationship: Relationship) {
//        //        updateRows()
//        let index = source.insert(relationship: relationship)
//        detailsTable.insertRows(at: IndexSet(integer: index + 1), withAnimation: .slideDown)
//    }
//
//    func removed(relationship: Relationship) {
//        if let row = source.remove(relationship: relationship) {
//            detailsTable.removeRows(at: IndexSet(integer: row), withAnimation: .slideUp)
//        }
//    }
//
//    func replaced(relationship: Relationship, with: Relationship) {
//        //        updateRows()
//        //        if let row = source.update(relationship: relationship, with: with) {
//        //            detailsTable.reloadData()
//        ////            detailsTable.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet([0,1,2]))
//        //        }
//    }
//
//    func removed(series: Series) {
//        if let row = source.remove(series: series) {
//            detailsTable.removeRows(at: IndexSet(integer: row), withAnimation: .slideUp)
//        }
//
//    }
//
//    func added(publisher: Publisher) {
//        let _ = source.insert(publisher: publisher)
//    }
//
//    func removed(publisher: Publisher) {
//        let _ = source.remove(publisher: publisher)
//    }
//
//    func created(books: [Book]) {
//        detailChannel.debug("books created")
//        DispatchQueue.main.async {
//            let info = ActionInfo(sender: self)
//            self.application.actionManager.perform(identifier: "StartEditing", info: info)
//        }
//    }
//
//    func deleted(books: [Book]) {
//        DispatchQueue.main.async {
//            self.application.actionManager.perform(identifier: "StopEditing")
//        }
//    }
//
//
//
//}
