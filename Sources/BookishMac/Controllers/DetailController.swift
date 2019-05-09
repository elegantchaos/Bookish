// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


import AppKit
import Actions
import Logger
import BookishModel

let detailChannel = Logger("Detail")
let detailCellChannel = Logger("DetailCell")

protocol KeyableTableCell {
    func keyView() -> NSView?
}

protocol DetailTableCell: KeyableTableCell {
    func setup(for row: DetailItem, of view: DetailController)
}

/**
 Table support, bindings, and IBActions have to live in a base class,
 as they can't go into a Swift generic class.
 */

class DetailController: CollectionViewController {
    static let unknownViewID = NSUserInterfaceItemIdentifier(rawValue: "unknown")

    let ImageSizeMax: CGFloat = 256
    let ImageSizeEditing: CGFloat = 64
    let ImageSizePlaceholder: CGFloat = 64

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
    @IBOutlet weak var imageWidth: NSLayoutConstraint!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    
    @objc var index: NSArrayController!

    var entityName: String = ""
    var entityType: ModelObject.Type = ModelObject.self
    var source = DetailProvider()
    var editing = false
    var indexView: IndexController!
    var keyViewTimer: Timer? = nil
    var observers = [NSObjectProtocol]()
    
    let doubleClickRecogniser = NSClickGestureRecognizer(target: self, action: #selector(textDoubleClick(_:)))
    let clickRecogniser = NSClickGestureRecognizer(target: self, action: #selector(chooseImage(_:)))

    func setup(for index: IndexController, type entityType: ModelObject.Type) {
        detailChannel.debug("setup for \(entityType)")
        doubleClickRecogniser.numberOfClicksRequired = 2
        clickRecogniser.numberOfClicksRequired = 1
        indexView = index
        self.index = index.indexArray
        self.entityName = String(describing: entityType)
        self.entityType = entityType
        source = entityType.getProvider()
        selectionChanged()
        
    }

    override func viewWillAppear() {
        let observer = NotificationCenter.default.addObserver(forName: CollectionViewState.ViewStateChangedNotification, object: nil, queue: nil) { (notification) in
            self.selectionChanged()
        }
        observers.append(observer)
        imageView.addGestureRecognizer(clickRecogniser)

        super.viewWillAppear()
    }

    override func viewWillDisappear() {
        let nc = NotificationCenter.default
        for observer in observers {
            nc.removeObserver(observer)
        }
        observers.removeAll()
        imageView.removeGestureRecognizer(clickRecogniser)

        super.viewWillDisappear()
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
        if visible {
            nameView.isEditable = source.isEditing
            if let path = source.titleProperty {
                let value = object.value(forKey: path) as? NSObject
                if value === NSMultipleValuesMarker {
                    nameView.placeholderString = "multiple items selected"
                    nameView.stringValue = ""
                } else {
                    nameView.objectValue = value
                }
            }
            addDoubleClickUnlock(to: nameView)
        }
    }
    
    fileprivate func updateSubtitle(for object: NSObject, visible: Bool) {
        if visible, let value = object.value(forKey: "summary") as? String, source.isEditing || !value.isEmpty {
            subtitleView.objectValue = value
            subtitleView.isHidden = false
            subtitleView.isEditable = source.isEditing
            addDoubleClickUnlock(to: subtitleView)
        } else {
            subtitleView.isHidden = true
        }
    }
    
    fileprivate func updateTable(visible: Bool) {
        if visible {
            detailChannel.debug("filtering details")

            detailsTable.headerView?.isHidden = !cvm.showDebug
            let selection = index?.selectedObjects as? [ModelObject] ?? []
            source.filter(for: selection, editing: editing, combining: true, context: cvm)

            detailsTable.reloadData()
            let visibleColumns = source.visibleColumns
            for column in detailsTable.tableColumns {
                column.isHidden = !visibleColumns.contains(column.identifier.rawValue)
                if column.isHidden {
                    print("hidden \(column)")
                }
            }
        }
        
        detailsTable.isHidden = !visible
    }
    
    fileprivate func updateImageSize(visible: Bool) {
        if visible, let image = imageView.image {
            let maxSize = source.isEditing ? ImageSizeEditing : ImageSizeMax
            let height = min(image.size.height, maxSize)
            let scale = height/image.size.height
            let width = image.size.width * scale
            imageHeight.constant = height
            imageWidth.constant = width
            imageView.isHidden = false
        } else {
            let hidden = !visible || !source.isEditing
            if !hidden {
                let placeholderName = "\(entityName)Placeholder"
                imageView.image = NSImage(named: placeholderName)
            }
            let size: CGFloat = hidden ? 0 : ImageSizePlaceholder
            imageHeight.constant = size
            imageWidth.constant = size
            imageView.isHidden = hidden
        }
    }
    
    fileprivate func updateImage(for object: NSObject, visible: Bool) {
        imageView.image = nil
        if visible {
            if let data = object.value(forKey: "image") as? Data, let image = NSImage(data: data) {
                imageView.image = image
                
            } else {
                if let urlString = object.value(forKey: "imageURL") as? String, let url = URL(string: urlString) {
                    application.imageCache.image(for: url) { (image) in
                        self.imageView.image = image
                        self.updateImageSize(visible: visible)
                    }
                }
            }
        }
        
        imageView.alphaValue = 1.0
        updateImageSize(visible: visible)
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
    
    func addDoubleClickUnlock(to control: NSControl) {
        if source.isEditing {
            control.removeGestureRecognizer(doubleClickRecogniser)
        } else {
            control.addGestureRecognizer(doubleClickRecogniser)
        }
    }
    
    @IBAction func textDoubleClick(_ sender: Any) {
        if !source.isEditing {
            application.actionManager.perform(identifier: "ToggleEditing")
        }
    }

    @IBAction func chooseImage(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowsOtherFileTypes = false
        panel.allowedFileTypes = NSImage.imageUnfilteredTypes
        panel.prompt = "detail.image.choose.prompt".localized
        panel.message = "detail.image.choose.message".localized
        application.windowController.showPanel(panel) { response in
            if let url = panel.url {
                if let image = NSImage(contentsOf: url) {
                    self.imageView.image = image
                    self.changeImage(sender)
                }
            }
        }

    }

    @IBAction func changeImage(_ sender: Any){
        if let image = imageView.image, let data = image.tiffRepresentation {
            ChangeValueAction.send("ChangeValue", from: self, manager: application.actionManager, property: "image", value: data)
        }
    }

}

// MARK: Other Indexes

extension DetailController {
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

extension DetailController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return source.combinedCount
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let columnID = tableColumn?.identifier else { return nil }
        
        let rowInfo = source.combinedInfo(row: row)
        let viewID = NSUserInterfaceItemIdentifier(rawValue: rowInfo.viewID(for: columnID.rawValue))
        
        guard let view = tableView.makeView(withIdentifier: viewID, owner: self) else {
            let view = tableView.makeView(withIdentifier: DetailController.unknownViewID, owner: self) as! NSTableCellView
            view.textField?.stringValue = "missing <\(viewID.rawValue)> cell"
            return view
        }
        
        if let cell = view as? DetailTableCell {
            detailCellChannel.log("made \(cell) for \(rowInfo)")
            cell.setup(for: rowInfo, of: self)
        }
        
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

extension DetailController: ActionContextProvider {
    func provide(context: ActionContext) {
        addContextForDetail(context: context)
        indexView.addContextForIndex(context: context)
    }
}

// MARK: EditableView Support

extension DetailController: EditableView {
    var isEditing: Bool { return editing }
    
    func setEditing(_ value: Bool) {
        editing = value
    }
    
    func willToggleEditing() {
        // change focus; this will commit any editing changes that were
        // in progress if we're turning editing off
        // NB need to do this before changing the editing flag, so that the
        // context is correct when any editing-related actions fire
        if editing {
            view.window?.makeFirstResponder(indexView)
        }
    }
    
    func didToggleEditing() {
        // rebuild the view on the next cycle, to give editing
        // changes a chance to get properly committed first
        DispatchQueue.main.async {
            self.selectionChanged()
            if self.editing {
                self.view.window?.makeFirstResponder(self.nameView)
            }
        }
    }
}


// MARK: Change Notifications

extension DetailController: BookChangeObserver {
    func added(relationship: Relationship) {
        let changes = source.inserted(details: [relationship])
        if changes.count > 0, let index = changes.last {
            detailsTable.insertRows(at: IndexSet(integer: index + 1), withAnimation: .slideDown)
        }
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
        detailsTable.reloadData(forRowIndexes: changes, columnIndexes: IndexSet([0,1,2]))
    }

    func changed(publisher: Publisher, to: Publisher) {
        let changes = source.inserted(details: [publisher])
        detailsTable.reloadData(forRowIndexes: changes, columnIndexes: IndexSet([0,1,2]))
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


extension DetailController: NSControlTextEditingDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        if let field = obj.object as? NSTextField {
            let property: String?
            switch field {
            case nameView:
                property = source.titleProperty
            default:
                property = nil
            }

            if let property = property {
                let sendAction: Bool
                let newValue = field.stringValue
                if let object = index.selection as? NSObject, let oldValue = object.value(forKey: property) as? String {
                    sendAction = oldValue != newValue
                } else {
                    sendAction = true
                }
                
                if sendAction {
                    let info = ActionInfo(sender: field)
                    info[ChangeValueAction.propertyKey] = property
                    info[ChangeValueAction.valueKey] = field.stringValue
                    application.actionManager.perform(identifier: "ChangeValue", info: info)
                }
            }
        }
    }
}
