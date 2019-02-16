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
    @IBOutlet weak var editButton: NSButton!
    @IBOutlet weak var personList: NSArrayController!
    @IBOutlet weak var publisherList: NSArrayController!
    @IBOutlet weak var seriesList: NSArrayController!
    @IBOutlet weak var roleList: NSArrayController!
    
    @objc var index: NSArrayController!

    var entityName: String = ""
    var source = DetailProvider()
    var editing = false
    var indexView: GenericIndexController!
    var keyViewTimer: Timer? = nil
    
    func setup(for index: GenericIndexController, type entityType: ModelObject.Type) {
        detailChannel.debug("setup for \(entityType)")
        indexView = index
        self.index = index.indexArray
        entityName = String(describing: entityType)
        source = entityType.getProvider()
        selectionChanged()
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
        for row in 0 ..< source.combinedCount {
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
    
    func addContextForDetail(context: ActionContext) {
        context.info.addObserver(self)
        context[ToggleEditingAction.editableKey] = self
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
    
    fileprivate func updateTitle(for object: NSObject, visible: Bool) {
        nameView.isHidden = !visible
        if let path = source.titleProperty {
            nameView.objectValue = object.value(forKey: path)
        }
    }
    
    fileprivate func updateSubtitle(for object: NSObject, visible: Bool) {
        if visible, let path = source.subtitleProperty, let value = object.value(forKey: path) as? String, source.isEditing || !value.isEmpty {
            subtitleView.objectValue = value
            subtitleView.isHidden = false
        } else {
            subtitleView.isHidden = true
        }
    }
    
    fileprivate func updateTable(visible: Bool) {
        if visible {
            detailChannel.debug("filtering details")
            
            let selection = index?.selectedObjects as? [ModelObject] ?? []
            source.filter(for: selection, editing: editing, combining: true, context: cvm)

            detailsTable.reloadData()
            let visibleColumns = source.visibleColumns
            for column in detailsTable.tableColumns {
                column.isHidden = !visibleColumns.contains(column.identifier.rawValue)
            }
        }
        
        detailsTable.isHidden = !visible
    }
    
    fileprivate func updateImage(for object: NSObject, visible: Bool) {
        imageView.isHidden = !visible
        if visible {
            if let data = object.value(forKey: "image") as? Data, let image = NSImage(data: data) {
                imageView.image = image
            } else {
                let placeholderName = "\(entityName)Placeholder"
                if let image = NSImage(named: placeholderName) {
                    imageView.image = image
                    
                    if let urlString = object.value(forKey: "imageURL") as? String, let url = URL(string: urlString) {
                        application.imageCache.image(for: url) { (image) in
                            self.imageView.image = image
                        }
                    }
                }
            }
        }
    }
    
    func selectionChanged() {
        detailChannel.debug("selection changed")
        let selectedCount = index.selectedObjects?.count ?? 0
        let showDetail = selectedCount > 0
        if let object = index.selection as? NSObject {
            updateTable(visible: showDetail)
            updateTitle(for: object, visible: showDetail)
            updateSubtitle(for: object, visible: showDetail)
            updateImage(for: object, visible: showDetail)
        }

        if let wc = view.window?.windowController as? CollectionWindowController {
            wc.validateButtons()
        }
    }
    

}

// MARK: Other Indexes

extension GenericDetailController {
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
        return source.combinedCount
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let columnID = tableColumn?.identifier else { return nil }
        
        let rowInfo = source.combinedInfo(row: row)
        let viewID = NSUserInterfaceItemIdentifier(rawValue: rowInfo.viewID(for: columnID.rawValue))
        
        guard let view = tableView.makeView(withIdentifier: viewID, owner: self) else {
            let view = tableView.makeView(withIdentifier: GenericDetailController.unknownViewID, owner: self) as! NSTableCellView
            view.textField?.stringValue = "missing <\(viewID.rawValue)> cell"
            return view
        }
        
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
        scheduleRecalculateKeyViews()
    }
    
    func tableView(_ tableView: NSTableView, didRemove rowView: NSTableRowView, forRow row: Int) {
        scheduleRecalculateKeyViews()
    }
}

// MARK: Action Support

extension GenericDetailController: ActionContextProvider {
    func provide(context: ActionContext) {
        addContextForDetail(context: context)
        indexView.addContextForIndex(context: context)
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
            self.selectionChanged()
        }
    }
}


// MARK: Change Notifications

extension GenericDetailController: BookChangeObserver {
    func added(relationship: Relationship) {
        let changes = source.inserted(details: [relationship])
        detailsTable.insertRows(at: changes, withAnimation: .slideDown)
    }

    func removed(relationship: Relationship) {
        let changes = source.removed(details: [relationship])
        detailsTable.removeRows(at: changes, withAnimation: .slideUp)
    }

    func replaced(relationship: Relationship, with: Relationship) {
        let changes = source.updated(details: [relationship], with: [with])
        detailsTable.reloadData(forRowIndexes: changes, columnIndexes: IndexSet([0,1,2]))
    }

    func removed(series: Series) {
        let changes = source.removed(details: [series])
        detailsTable.removeRows(at: changes, withAnimation: .slideUp)
    }

    func added(publisher: Publisher) {
        let changes = source.inserted(details: [publisher])
        detailsTable.insertRows(at: changes, withAnimation: .slideDown)
    }

    func removed(publisher: Publisher) {
        let changes = source.removed(details: [publisher])
        detailsTable.removeRows(at: changes, withAnimation: .slideUp)
    }

    func created(books: [Book]) {
        detailChannel.debug("books created")
        DispatchQueue.main.async {
            let info = ActionInfo(sender: self)
            self.application.actionManager.perform(identifier: "StartEditing", info: info)
        }
    }

    func deleted(books: [Book]) {
        DispatchQueue.main.async {
            self.application.actionManager.perform(identifier: "StopEditing")
        }
    }



}
