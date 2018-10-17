// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel
import Dispatch

class PersonDetailViewController: CollectionViewController {
    @IBOutlet weak var nameView: NSTextField!
    @IBOutlet weak var notesView: NSTextField!
    @IBOutlet weak var indexView: PersonIndexViewController!
    @IBOutlet weak var detailsView: NSTableView!

    var indexObserver: NSKeyValueObservation?
    var rows = [NSManagedObject]()
    var availableRows = IndexSet()
    var keyViewTimer: Timer? = nil

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

    func selectedPersonRoles() -> [PersonRole] {
        var result = [PersonRole]()
        if let selection = indexView.indexArray.selectedObjects as? [Person] {
            for person in selection {
                if let roles = person.personRoles as? Set<PersonRole> {
                    result.append(contentsOf: roles)
                }
            }
        }
        return result
    }
    
    func rowsForSelection() -> [NSManagedObject] {
        var booksByRole = [Role:Set<Book>]()
        let selected = selectedPersonRoles()
        for personRole in selected {
            if let role = personRole.role, let prb = personRole.books as? Set<Book> {
                var books = booksByRole[role]
                if books == nil {
                    books = Set<Book>()
                    books?.formUnion(prb)
                    booksByRole[role] = books
                } else {
                    books?.formIntersection(prb)
                }
            }
        }
        
        var rows: [NSManagedObject] = []
        for role in Role.allRoles(context: cvm.managedObjectContext) {
            if let books = booksByRole[role] {
                rows.append(role)
                rows.append(contentsOf: books)
            }
        }
        
        return rows
    }
    
    func selectionChanged() {
        let selectedCount = indexView.indexArray.selectedObjects?.count ?? 0
        let showDetail = selectedCount > 0
        detailsView.isHidden = !showDetail
        if showDetail {
            updateRoles()
        }
        if let wc = view.window?.windowController as? CollectionWindowController {
            wc.validateButtons()
        }
    }
    
    func updateRoles() {
        rows = rowsForSelection()
        detailsView.reloadData()

    }
}

// MARK: Table Support

extension PersonDetailViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    static let bookViewID = NSUserInterfaceItemIdentifier(rawValue: "book")
    static let roleViewID = NSUserInterfaceItemIdentifier(rawValue: "role")
    static let unknownViewID = NSUserInterfaceItemIdentifier(rawValue: "unknown")

    func numberOfRows(in tableView: NSTableView) -> Int {
        return rows.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < rows.count else {
            return nil
        }

        let label: String
        let viewID: NSUserInterfaceItemIdentifier
        let item = rows[row]
        if let role = item as? Role, let name = role.name {
            label = name
            viewID = PersonDetailViewController.roleViewID
        } else if let book = item as? Book, let name = book.name {
            label = name
            viewID = PersonDetailViewController.bookViewID
       } else {
            label = ""
            viewID = PersonDetailViewController.unknownViewID
        }

        let view = tableView.makeView(withIdentifier: viewID, owner: self)
        if let field = view?.subviews.first as? NSTextField {
            field.stringValue = label
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
        let rows = availableRows.sorted()
        var view: NSView = notesView
        for row in rows {
            if let rowView = (detailsView.view(atColumn: 0, row: row, makeIfNecessary: false) as? BindableCellView)?.viewToBind() {
                view.nextKeyView = rowView
                view = rowView
            }
        }
        view.nextKeyView = nameView
        keyViewTimer = nil
    }
}

// MARK: Actions

extension PersonDetailViewController: ActionContextProvider {
    func provideDetailInfo(context: ActionContext) {
        if let selection = indexView.indexArray.selectedObjects as? [Person] {
            context.info[ActionContext.selectionKey] = selection
            if let view = context.sender as? NSView {
                let row = detailsView.row(for: view)
                if row >= 0 {
                    context.info[BookAction.bookKey] = rows[row] as? Book
                }
            }
        }
    }
    
    func provide(context: ActionContext) {
        indexView.provideIndexInfo(context: context)
        provideDetailInfo(context: context)
    }
}
