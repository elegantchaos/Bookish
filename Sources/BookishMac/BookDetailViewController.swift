// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel
import Dispatch

enum RowType {
    case text
    case date
}

struct RowSpecification {
    let binding: String
    let label: String
    let type: RowType
    let editable: Bool
    
    init(binding: String, label: String? = nil, type: RowType = .text, editable: Bool = true) {
        self.binding = binding
        self.label = label ?? binding
        self.type = type
        self.editable = editable
    }
}
class BookDetailViewController: CollectionViewController {
    @IBOutlet weak var indexView: BookIndexViewController!
    @IBOutlet weak var detailsView: NSTableView!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var titleView: NSTextField!
    @IBOutlet weak var subtitleView: NSTextField!
    
    var people = [PersonRole]()
    var indexObserver: NSKeyValueObservation?
    var availableRows = IndexSet()
    var keyViewTimer: Timer? = nil
    
    let rows = [
        RowSpecification(binding: "format"),
        RowSpecification(binding: "isbn"),
        RowSpecification(binding: "notes"),
        RowSpecification(binding: "published", type: .date),
        RowSpecification(binding: "added", type: .date, editable: false),
        RowSpecification(binding: "modified", type: .date, editable: false)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        indexView = nearestSibling()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()

        if let window = view.window?.windowController as? CollectionWindowController {
            window.bookDetailController = self
        }
        
        if let indexArray = indexView.indexArray {
            titleView.bind(NSBindingName(rawValue: "value"), to:indexArray, withKeyPath:"selection.name", options: [:])
            subtitleView.bind(NSBindingName(rawValue: "value"), to:indexArray, withKeyPath:"selection.subtitle", options: [:])
            imageView.bind(NSBindingName(rawValue: "value"), to:indexArray, withKeyPath:"selection.image", options: [NSBindingOption.valueTransformerName:"CoverImage"])
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
        people = common.sorted(by: { ($0.person?.name ?? "") < ($1.person?.name ?? "") })
        detailsView.reloadData()
    }
}


// MARK: Actions

extension BookDetailViewController: ActionContextProvider, PersonChangeObserver {
    func provide(context: ActionContext) {
        if let selection = indexView.indexArray.selectedObjects as? [Book] {
            context.info[ActionContext.selectionKey] = selection
            context.append(key: PersonAction.observerKey, value: self)
            if let view = view.window?.firstResponder as? NSView {
                let row = detailsView.row(for: view)
                if row >= 0 {
                    if (row < people.count) {
                        context.info[PersonAction.roleKey] = people[row]
                    } else {
                        if let valueView = detailsView.view(atColumn: 1, row: row, makeIfNecessary: false) as? BindableCellView {
                            let rowInfo = rows[row - people.count]
                            let valueObject = valueView.objectValue
                            context.info["object"] = valueObject
                            context.info["binding"] = rowInfo.binding
                        }
                    }
                }
            }
        }
    }
    
    func added(role: PersonRole) {
        let count = people.count
        people.append(role)
        detailsView.insertRows(at: IndexSet(integer: count), withAnimation: .slideDown)
    }
    
    func removed(role: PersonRole) {
        if let row = people.firstIndex(of: role) {
            people.remove(at: row)
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
    static let ValueColumnID = NSUserInterfaceItemIdentifier(rawValue: "value")
    static let PersonColumnID = NSUserInterfaceItemIdentifier(rawValue: "person")
    static let DateColumnID = NSUserInterfaceItemIdentifier(rawValue: "date")
        
    func rowInfo(for tableView: NSTableView, columnID: NSUserInterfaceItemIdentifier, row: Int) -> (NSView?, Bool, Bool, Int) {
        var viewID = columnID
        let isPerson = row < people.count
        let isValue = columnID == BookDetailViewController.ValueColumnID
        let index = isPerson ? row : row - people.count
        if isValue {
            if isPerson {
                viewID = BookDetailViewController.PersonColumnID
            } else if rows[index].type == .date {
                viewID = BookDetailViewController.DateColumnID
            }
        }
        
        let view = tableView.makeView(withIdentifier: viewID, owner: self)
        return (view, isPerson, isValue, index)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return rows.count + people.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < (rows.count + people.count), let columnID = tableColumn?.identifier else {
            return nil
        }
        
        let (view, isPerson, isValue, index) = rowInfo(for: tableView, columnID: columnID, row: row)
        
        if !isValue, let field = view?.subviews.first as? NSTextField {
            if isPerson {
                field.stringValue = people[index].role?.name ?? "<unknown role>"
            } else {
                field.stringValue = rows[index].label
            }
        } else if isValue, var bindable = view as? BindableCellView, let subview = bindable.viewToBind() {
            var options = [NSBindingOption:Any]()
            if !isPerson && (rows[index].type == .date) {
                options[.valueTransformer] = ValueTransformer(forName: NSValueTransformerName(rawValue: "DateToString"))
                if let textView = subview as? NSTextField {
                    let unlocked = rows[index].editable
                    options[.conditionallySetsEditable] = unlocked
                    textView.isSelectable = unlocked
                    textView.isEditable = unlocked
                }
            }
            let bound: Any = isPerson ? people[index] : indexView.indexArray
            let path = isPerson ? "person.name" : "selection.\(rows[index].binding)"
            subview.bind(NSBindingName(rawValue: "value"), to:bound, withKeyPath:path, options: options)
            if isPerson {
                subview.identifier = NSUserInterfaceItemIdentifier(rawValue: "person-\(row)")
            } else {
                subview.identifier = NSUserInterfaceItemIdentifier(rawValue: "detail-\(rows[index].binding)")
                bindable.objectValue = indexView.indexArray.selection as? NSObject
            }
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
