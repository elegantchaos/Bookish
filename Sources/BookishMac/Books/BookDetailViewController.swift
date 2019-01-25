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
    static let ControlColumnID = NSUserInterfaceItemIdentifier(rawValue: "control")

    @IBOutlet weak var subtitleView: NSTextField!
    @IBOutlet weak var controlColumn: NSTableColumn!
    @IBOutlet weak var editButton: NSButton!
    @IBOutlet weak var personList: NSArrayController!
    @IBOutlet weak var publisherList: NSArrayController!
    @IBOutlet weak var seriesList: NSArrayController!
    @IBOutlet weak var roleList: NSArrayController!
    
    var source = DetailDataSource()
    var editing = false
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        detailChannel.debug("appearing")
        personList.sortDescriptors = cvm.personSorting
        calculateRows()
        adjustControlsForEditing()
    }
 

    func calculateRows() {
        let selection = (index.selectedObjects as? [Book]) ?? []
        source.filter(for: selection, editing: editing)
    }

    override func updateRows() {
        detailChannel.debug("updating people list")

        calculateRows()
        detailsTable.reloadData()
    }
 
    override func numberOfRows(in tableView: NSTableView) -> Int {
        return source.rows
    }
    
    override func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let columnID = tableColumn?.identifier else { return nil }
        
        let rowInfo = source.info(for: row)
        let viewID = NSUserInterfaceItemIdentifier(rawValue: rowInfo.viewID(for: columnID.rawValue))
        
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
    
    override func addContextForDetail(context: ActionContext) {
        context.info.addObserver(self)
        if let selection = index.selectedObjects as? [Book] {
            context.info[ActionContext.selectionKey] = selection
            context.info[ToggleEditingAction.editableKey] = self
        }
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
}

// MARK: EditableView Support

extension BookDetailViewController: EditableView {
    func toggleEditing() {
        // change focus; this will commit any editing changes that were
        // in progress if we're turning editing off
        // NB need to do this before changing the editing flag, so that the
        // context is correct when any editing-related actions fire
        let newResponder: NSResponder = editing ? nameView : indexView
        view.window?.makeFirstResponder(newResponder)
        
        editing = !editing

        // rebuild the view on the next cycle, to give editing
        // changes a chance to get properly committed first
        DispatchQueue.main.async {
            self.adjustControlsForEditing()
            self.selectionChanged()
        }
    }

    func adjustControlsForEditing() {
        controlColumn.isHidden = !editing
        editButton.title = editing ? "Done" : "Edit"
        detailChannel.debug(editing ? "enabled editing" : "disabled editing")
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
//        updateRows()
        let index = source.insert(relationship: relationship)
        detailsTable.insertRows(at: IndexSet(integer: index + 1), withAnimation: .slideDown)
    }
    
    func removed(relationship: Relationship) {
        if let row = source.remove(relationship: relationship) {
            detailsTable.removeRows(at: IndexSet(integer: row), withAnimation: .slideUp)
        }
    }

    func replaced(relationship: Relationship, with: Relationship) {
//        updateRows()
//        if let row = source.update(relationship: relationship, with: with) {
//            detailsTable.reloadData()
            ////            detailsTable.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet([0,1,2]))
//        }
    }
    
    func removed(series: Series) {
        if let row = source.remove(series: series) {
            detailsTable.removeRows(at: IndexSet(integer: row), withAnimation: .slideUp)
        }

    }
    
    func removed(publisher: Publisher) {
        if let row = source.remove(publisher: publisher) {
            detailsTable.removeRows(at: IndexSet(integer: row), withAnimation: .slideUp)
        }
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

protocol BookDetailTableCell: KeyableTableCell {
    func setup(for: BookDetailViewController, row: DetailDataSource.RowInfo)
}
