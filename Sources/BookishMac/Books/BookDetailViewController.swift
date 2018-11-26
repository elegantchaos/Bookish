// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel
import Dispatch

class BookDetailViewController: CollectionViewController {
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

        if let window = view.window?.windowController as? CollectionWindowController {
            window.bookDetailController = self
        }
        
        personList.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
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
        let selection = (indexView.indexArray.selectedObjects as? [Book]) ?? []
        source.filter(for: selection, editing: editing)
        detailsView.reloadData()
    }
}


// MARK: Local IBActions

extension BookDetailViewController {
    @IBAction func toggleEditing(_ sender: Any) {
        editing = !editing
        editButton.title = editing ? "Done" : "Edit…"
        selectionChanged()
        if editing {
            titleView.becomeFirstResponder()
        } else {
            view.window?.makeFirstResponder(nil)
        }
    }
    
    @IBAction func changeImage(_ sender: Any){
        print("change image")
    }
    
}


// MARK: Action Support

extension BookDetailViewController: ActionContextProvider, PersonChangeObserver {
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
    
    func provide(context: ActionContext) {
        if let selection = indexView.indexArray.selectedObjects as? [Book] {
            context.info[ActionContext.selectionKey] = selection
            context.info.addObserver(self)
        }
    }
    
    func added(role: Relationship) {
        let index = source.insert(relationship: role)
        detailsView.insertRows(at: IndexSet(integer: index), withAnimation: .slideDown)
        availableRows.insert(index)
        scheduleRecalculateKeyViews()
    }
    
    func removed(role: Relationship) {
        if let row = source.remove(relationship: role) {
            detailsView.removeRows(at: IndexSet(integer: row), withAnimation: .slideUp)
            availableRows.remove(row)
            scheduleRecalculateKeyViews()
        }
    }
}


// MARK: Table Support

protocol BookDetailTableCell {
    func setup(for: BookDetailViewController, row: Int, isPerson: Bool)
    func keyView() -> NSView?
}

extension BookDetailViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    static let HeadingColumnID = NSUserInterfaceItemIdentifier(rawValue: "heading")
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return source.rows
    }

        
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let columnID = tableColumn?.identifier else { return nil }
        
        let (kind, isPerson) = source.info(for: row, editing: editing)
        let headingID = BookDetailViewController.HeadingColumnID
        let isHeading = columnID == headingID
        let viewID = isHeading ? headingID : NSUserInterfaceItemIdentifier(rawValue: kind.rawValue)
        
        guard let view = tableView.makeView(withIdentifier: viewID, owner: self) else { return nil }
        if let cell = view as? BookDetailTableCell {
            cell.setup(for: self, row: row, isPerson: isPerson)
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
