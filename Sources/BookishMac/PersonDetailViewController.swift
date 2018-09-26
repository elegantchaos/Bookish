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
    var roles = [PersonRole]()
    var availableRows = IndexSet()
    var keyViewTimer: Timer? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        indexView = nearestSibling()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
//        if let window = view.window?.windowController as? CollectionWindowController {
//            window.bookDetailController = self
//        }
        
        if let indexArray = indexView.indexArray {
            nameView.bind(NSBindingName(rawValue: "value"), to:indexArray, withKeyPath:"selection.name", options: [:])
            notesView.bind(NSBindingName(rawValue: "value"), to:indexArray, withKeyPath:"selection.notes", options: [:])
//            imageView.bind(NSBindingName(rawValue: "value"), to:indexArray, withKeyPath:"selection.image", options: [NSBindingOption.valueTransformerName:"CoverImage"])
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

    func rolesInSelection() -> (Set<PersonRole>, Set<PersonRole>) {
        var all = Set<PersonRole>()
        var common = Set<PersonRole>()
        if let selection = indexView.indexArray.selectedObjects as? [Person] {
            for person in selection {
                if let roles = person.personRoles as? Set<PersonRole> {
                    if all.count == 0 {
                        common.formUnion(roles)
                    } else {
                        common.formIntersection(roles)
                    }
                    all.formUnion(roles)
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
            updateRoles()
        }
        if let wc = view.window?.windowController as? CollectionWindowController {
            wc.validateButtons()
        }
    }
    
    func updateRoles() {
        let (_, common) = rolesInSelection()
        roles = common.sorted(by: { ($0.person?.name ?? "") < ($1.person?.name ?? "") })
        detailsView.reloadData()

    }
}

// MARK: Table Support

extension PersonDetailViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    static let HeadingColumnID = NSUserInterfaceItemIdentifier(rawValue: "heading")
    static let ValueColumnID = NSUserInterfaceItemIdentifier(rawValue: "value")
    static let PersonColumnID = NSUserInterfaceItemIdentifier(rawValue: "person")
    static let DateColumnID = NSUserInterfaceItemIdentifier(rawValue: "date")
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return roles.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < roles.count, let columnID = tableColumn?.identifier else {
            return nil
        }
        
        let view = tableView.makeView(withIdentifier: columnID, owner: self)
        if let field = view?.subviews.first as? NSTextField {
            let role = roles[row]
            if let name = role.role?.name {
                field.stringValue = name
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
        var view: NSView = notesView
        for row in rows {
            if let rowView = (detailsView.view(atColumn: 1, row: row, makeIfNecessary: false) as? BindableCellView)?.viewToBind() {
                view.nextKeyView = rowView
                view = rowView
            }
        }
        view.nextKeyView = nameView
        keyViewTimer = nil
    }
}
