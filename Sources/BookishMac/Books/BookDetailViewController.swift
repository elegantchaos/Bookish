// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel
import Dispatch
import Logger

let bookDetailChannel = Logger("BookDetail")

class BookDetailViewController: CollectionViewController, BookLifecycleObserver {
    @IBOutlet weak var indexView: BookIndexViewController!
    @IBOutlet weak var detailsView: NSTableView!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var titleView: NSTextField!
    @IBOutlet weak var subtitleView: NSTextField!
    
    @IBOutlet weak var editButton: NSButton!
    @IBOutlet var personList: NSArrayController!
    
    var source = DetailDataSource()
    var indexObserver: NSKeyValueObservation?
    var availableRows = IndexSet()
    var keyViewTimer: Timer? = nil
    var bookImage: NSImage?
    var editing = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        indexView = nearestSibling()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        bookDetailChannel.debug("appearing")
        
        personList.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        if let indexArray = indexView.indexArray {
            indexObserver = indexArray.observe(\NSArrayController.selection, changeHandler: { (index, change) in
                self.selectionChanged()
            })
            selectionChanged()
        }
    }
 
    override func viewWillDisappear() {
        bookDetailChannel.debug("disappearing")
        
        indexObserver = nil
        super.viewWillDisappear()
    }
    
    func selectionChanged() {
        bookDetailChannel.debug("selection changed")
        
        let selectedCount = indexView.indexArray.selectedObjects?.count ?? 0
        let showDetail = selectedCount > 0
        detailsView.isHidden = !showDetail
        if showDetail {
            updatePeople()
        }
        if let wc = view.window?.windowController as? CollectionWindowController {
            wc.validateButtons()
        }
        
        if selectedCount == 1 {
            if let book = indexView.indexArray.selectedObjects[0] as? Book {
                if let data = book.image, let image = NSImage(data: data) {
                    imageView.image = image
                } else {
                    imageView.image = NSImage(named: "CoverPlaceholder")
                    if let urlString = book.imageURL, let url = URL(string: urlString) {
                        application.imageCache.image(for: url) { (image) in
                            self.imageView.image = image
                        }
                    }
                }
            }
        }
    }
    
    func updatePeople() {
        bookDetailChannel.debug("updating people list")

        let selection = (indexView.indexArray.selectedObjects as? [Book]) ?? []
        source.filter(for: selection, editing: editing)
        detailsView.reloadData()
    }
}

// MARK: EditableView Support

extension BookDetailViewController: EditableView {
    func toggleEditing() {
        editing = !editing
        editButton.title = editing ? "Done" : "Edit"
        bookDetailChannel.debug(editing ? "enabled editing" : "disabled editing")
        let newResponder: NSResponder = editing ? titleView : indexView
        view.window?.makeFirstResponder(newResponder)
        selectionChanged()
    }

}

// MARK: Local IBActions

extension BookDetailViewController {
    
    @IBAction func changeImage(_ sender: Any){
        print("change image")
    }
    
}


// MARK: Action Support

extension BookDetailViewController: ActionContextProvider, BookChangeObserver {

    
    func detailRow(for context: ActionContext) -> Int {
        var row = -1
        if let view = context.sender as? NSView {
            row = detailsView.row(for: view)
        }

        if row < 0, let view = view.window?.firstResponder as? NSView {
            row = detailsView.row(for: view)
        }

        return row
    }
    
    func provideForDetail(context: ActionContext) {
        context.info.addObserver(self)
        if let selection = indexView.indexArray.selectedObjects as? [Book] {
            context.info[ActionContext.selectionKey] = selection
            context.info[ToggleEditingAction.editableKey] = self
        }
    }

    func provide(context: ActionContext) {
        provideForDetail(context: context)
        indexView.provideForIndex(context: context)
    }
    
    func added(relationship: Relationship) {
        let index = source.insert(relationship: relationship)
        detailsView.insertRows(at: IndexSet(integer: index), withAnimation: .slideDown)
        availableRows.insert(index)
        scheduleRecalculateKeyViews()
    }
    
    func removed(relationship: Relationship) {
        if let row = source.remove(relationship: relationship) {
            detailsView.removeRows(at: IndexSet(integer: row), withAnimation: .slideUp)
            availableRows.remove(row)
            scheduleRecalculateKeyViews()
        }
    }

    func added(series: Series) {
        
    }
    
    func removed(series: Series) {
        
    }
    
    func added(publisher: Publisher) {
        
    }
    
    func removed(publisher: Publisher) {
        
    }
    
    func created(books: [Book]) {
        bookDetailChannel.debug("books created")
        if !self.editing {
            DispatchQueue.main.async {
                self.toggleEditing()
            }
        }
    }
    
    func deleted(books: [Book]) {
        DispatchQueue.main.async {
            if self.editing {
                self.toggleEditing()
            }
        }
    }
}


// MARK: Table Support

protocol BookDetailTableCell {
    func setup(for: BookDetailViewController, row: DetailDataSource.RowInfo)
    func keyView() -> NSView?
}

extension BookDetailViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    static let HeadingColumnID = NSUserInterfaceItemIdentifier(rawValue: "heading")
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return source.rows
    }

        
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let columnID = tableColumn?.identifier else { return nil }
        
        let rowInfo = source.info(for: row, editing: editing)
        let headingID = BookDetailViewController.HeadingColumnID
        let isHeading = columnID == headingID
        let viewID = isHeading ? headingID : NSUserInterfaceItemIdentifier(rawValue: rowInfo.kind.rawValue)
        
        guard let view = tableView.makeView(withIdentifier: viewID, owner: self) else { return nil }
        if let cell = view as? BookDetailTableCell {
            cell.setup(for: self, row: rowInfo)
        }
        view.scheduleForValidation()
        
        return view
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        AnnotatedTableCellView.updateSelection(tableView: tableView, row: row)
        return true
    }
    
    fileprivate func scheduleRecalculateKeyViews() {
        if let timer = keyViewTimer {
            timer.invalidate()
        }
        
        keyViewTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            self.recalculateKeyViews()
        }
    }
    
    fileprivate func recalculateKeyViews() {
        let rows = availableRows.sorted()
        var view: NSView = subtitleView
        for row in rows {
            if let rowView = (detailsView.view(atColumn: 1, row: row, makeIfNecessary: false) as? BookDetailTableCell)?.keyView() {
                view.nextKeyView = rowView
                view = rowView
            }
        }
        view.nextKeyView = titleView
        keyViewTimer = nil
    }
}
