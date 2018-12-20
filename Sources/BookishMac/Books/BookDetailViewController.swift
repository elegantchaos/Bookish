// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel
import Dispatch
import Logger

class BookDetailViewController: DetailController<Book>, BookLifecycleObserver {
    static let HeadingColumnID = NSUserInterfaceItemIdentifier(rawValue: "heading")

    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var subtitleView: NSTextField!
    
    @IBOutlet weak var editButton: NSButton!
    @IBOutlet var personList: NSArrayController!
    
    var source = DetailDataSource()
    var bookImage: NSImage?
    var editing = false
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        detailChannel.debug("appearing")
        
        personList.sortDescriptors = cvm.personSorting
    }
 

    
    override func selectionChanged() {
        super.selectionChanged()
        let selectedCount = index?.selectedObjects?.count ?? 0
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
    
    override func updateRows() {
        detailChannel.debug("updating people list")

        let selection = (indexView.indexArray.selectedObjects as? [Book]) ?? []
        source.filter(for: selection, editing: editing)
        detailsTable.reloadData()
    }
 
    override func numberOfRows(in tableView: NSTableView) -> Int {
        return source.rows
    }
    
    override func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
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
    
    override func provideForDetail(context: ActionContext) {
        context.info.addObserver(self)
        if let selection = indexView.indexArray.selectedObjects as? [Book] {
            context.info[ActionContext.selectionKey] = selection
            context.info[ToggleEditingAction.editableKey] = self
        }
    }

}

// MARK: EditableView Support

extension BookDetailViewController: EditableView {
    func toggleEditing() {
        editing = !editing
        editButton.title = editing ? "Done" : "Edit"
        detailChannel.debug(editing ? "enabled editing" : "disabled editing")
        let newResponder: NSResponder = editing ? nameView : indexView
        view.window?.makeFirstResponder(newResponder)
        selectionChanged()
    }

}

// MARK: Local IBActions

extension BookDetailViewController {
     
}


// MARK: Action Support

extension BookDetailViewController: BookChangeObserver {

    
    func detailRow(for context: ActionContext) -> Int {
        var row = -1
        if let view = context.sender as? NSView {
            row = detailsTable.row(for: view)
        }

        if row < 0, let view = view.window?.firstResponder as? NSView {
            row = detailsTable.row(for: view)
        }

        return row
    }
    
    
    func added(relationship: Relationship) {
        let index = source.insert(relationship: relationship)
        detailsTable.insertRows(at: IndexSet(integer: index), withAnimation: .slideDown)
    }
    
    func removed(relationship: Relationship) {
        if let row = source.remove(relationship: relationship) {
            detailsTable.removeRows(at: IndexSet(integer: row), withAnimation: .slideUp)
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
        detailChannel.debug("books created")
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
