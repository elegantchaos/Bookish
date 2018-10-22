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
    
    var source = DetailDataSource()
    var indexObserver: NSKeyValueObservation?
    var availableRows = IndexSet()
    var keyViewTimer: Timer? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        indexView = nearestSibling()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()

        if let window = view.window?.windowController as? CollectionWindowController {
            window.bookDetailController = self
        }
        
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
    
    func peopleInSelection() -> (Set<PersonRole>, Set<PersonRole>) {
        var all = Set<PersonRole>()
        var common = Set<PersonRole>()
        if let selection = indexView.indexArray.selectedObjects as? [Book] {
            for book in selection {
                if let people = book.personRoles as? Set<PersonRole> {
                    if all.count == 0 {
                        common.formUnion(people)
                    } else {
                        common.formIntersection(people)
                    }
                    all.formUnion(people)
                }
            }
        }
        return (all, common)
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
    }
    
    func updatePeople() {
        let (_, common) = peopleInSelection()
        source.people = common.sorted(by: { ($0.person?.name ?? "") < ($1.person?.name ?? "") })
        detailsView.reloadData()
    }
}


// MARK: Actions

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
            context.addObserver(self)
            let row = detailRow(for: context)
            if row >= 0 {
                let info = source.info(for: row)
                if (info.isPerson) {
                    context.info[PersonAction.roleKey] = source.person(for: row)
                } else {
                    if let valueView = detailsView.view(atColumn: 1, row: row, makeIfNecessary: false) as? BindableCellView {
                        let detail = source.details(for: row)
                        let valueObject = valueView.objectValue
                        context.info["object"] = valueObject
                        context.info["binding"] = detail.binding
                    }
                }
            }
        }
    }
    
    func added(role: PersonRole) {
        let index = source.insert(personRole: role)
        detailsView.insertRows(at: IndexSet(integer: index), withAnimation: .slideDown)
    }
    
    func removed(role: PersonRole) {
        if let row = source.remove(personRole: role) {
            detailsView.removeRows(at: IndexSet(integer: row), withAnimation: .slideUp)
        }
    }
}


// MARK: Table Support

protocol BindableCellView {
    func viewToBind() -> NSView?
    var objectValue: Any? { get set }
}

extension NSTableCellView: BindableCellView {
    func viewToBind() -> NSView? {
        return textField
    }
}

extension BookDetailViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    static let HeadingColumnID = NSUserInterfaceItemIdentifier(rawValue: "heading")
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return source.rows
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let columnID = tableColumn?.identifier else {
            return nil
        }
        
        let info = source.info(for: row)
        let isHeading = columnID == BookDetailViewController.HeadingColumnID
        let viewID = isHeading ? BookDetailViewController.HeadingColumnID : NSUserInterfaceItemIdentifier(rawValue: info.identifier)
        let view = tableView.makeView(withIdentifier: viewID, owner: self)

        if isHeading {
            setupHeading(view: view, row: row, info: info)
        } else if !isHeading {
            setupValue(view: view, row: row, info: info)
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
    
    fileprivate func setupHeading(view: NSView?, row: Int, info: DetailDataSource.RowInfo) {
        if let field = view?.subviews.first as? NSTextField {
            if info.isPerson {
                field.stringValue = source.person(for: row).role?.name ?? "<unknown role>"
            } else {
                field.stringValue = source.details(for: row).label
            }
        }
    }
    
    fileprivate func setupValue(view: NSView?, row: Int, info: DetailDataSource.RowInfo) {
        if var bindable = view as? BindableCellView, let subview = bindable.viewToBind() {
            var options = [NSBindingOption:Any]()
            let bound: Any
            let path: String
            let subviewID: NSUserInterfaceItemIdentifier
            if info.isPerson {
                bound = source.person(for: row)
                path = "person.name"
                subviewID = NSUserInterfaceItemIdentifier(rawValue: "person-\(row)")
            } else {
                let detail = source.details(for: row)
                bound = indexView.indexArray
                path = "selection.\(detail.binding)"
                if detail.kind == .date {
                    options[.valueTransformer] = ValueTransformer(forName: NSValueTransformerName(rawValue: "DateToString"))
                    if let textView = subview as? NSTextField {
                        let unlocked = detail.editable
                        options[.conditionallySetsEditable] = unlocked
                        textView.isSelectable = unlocked
                        textView.isEditable = unlocked
                    }
                }
                subviewID = NSUserInterfaceItemIdentifier(rawValue: "detail-\(detail.binding)")
                bindable.objectValue = indexView.indexArray.selection as? NSObject
            }
            
            subview.bind(NSBindingName(rawValue: "value"), to:bound, withKeyPath:path, options: options)
            subview.identifier = subviewID
        }
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
            if let rowView = (detailsView.view(atColumn: 1, row: row, makeIfNecessary: false) as? BindableCellView)?.viewToBind() {
                view.nextKeyView = rowView
                view = rowView
            }
        }
        view.nextKeyView = titleView
        keyViewTimer = nil
    }
}
