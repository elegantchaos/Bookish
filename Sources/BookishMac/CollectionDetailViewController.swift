// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Cocoa
import BookishModel

struct RowSpecification {
    let binding: String
    let label: String
}

class CollectionDetailViewController: CollectionViewController, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet weak var indexView: CollectionIndexViewController!
    @IBOutlet weak var indexArray: NSArrayController!
    @IBOutlet weak var detailsView: NSTableView!
    @IBOutlet weak var peopleView: NSTableView!
    
    var people = [PersonEntry]()
    var indexObserver: NSKeyValueObservation?
    
    let rows = [
        RowSpecification(binding: "name", label: "name"),
        RowSpecification(binding: "notes", label: "notes"),
        RowSpecification(binding: "subtitle", label: "subtitle"),
        RowSpecification(binding: "format", label: "format"),
        RowSpecification(binding: "isbn", label: "isbn"),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: this is a bit naff as it makes assumptions about the containment hierarchy
        if let parent = self.parent as? NSSplitViewController {
            indexView = parent.splitViewItems[0].viewController as? CollectionIndexViewController
        }
        
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()

        indexArray.fetch(self)
        indexObserver = indexArray.observe(\NSArrayController.selection, changeHandler: { (index, change) in
            self.updatePeople()
        })
    }
 
    override func viewWillDisappear() {
        indexObserver = nil
        super.viewWillDisappear()
    }
    
    func updatePeople() {
        var all = Set<PersonEntry>()
        var common = Set<PersonEntry>()
        if let selection = indexArray.selectedObjects as? [Book] {
            for book in selection {
                if let people = book.people as? Set<PersonEntry> {
                    if all.count == 0 {
                        common.formUnion(people)
                    } else {
                        common.formIntersection(people)
                    }
                    all.formUnion(people)
                }
            }
            self.people = common.sorted(by: { ($0.person?.name ?? "") < ($1.person?.name ?? "") })
        }
        
        self.peopleView.reloadData()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == detailsView {
            return rows.count
        } else {
            return people.count
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var view: NSView? = nil
        if tableView == detailsView {
            if row < rows.count, let columnID = tableColumn?.identifier {
                let columnName = columnID.rawValue
                let rowSpec = rows[row]
                view = tableView.makeView(withIdentifier: columnID, owner: self)
                if columnName == "heading", let field = view as? NSTextField {
                    field.stringValue = rowSpec.label
                }
                    
                else if columnName == "value" {
                    if let subview = view?.subviews.first as? NSTextField {
                        subview.bind(NSBindingName(rawValue: "value"), to:indexArray, withKeyPath:"selection.\(rowSpec.binding)", options: [:])
                    }
                }
            }
        } else {
            if row < people.count, let columnID = tableColumn?.identifier {
                let columnName = columnID.rawValue
                let entry = people[row]
                view = tableView.makeView(withIdentifier: columnID, owner: self)
                if columnName == "role", let field = view as? NSTableCellView {
                    field.objectValue = entry.role?.name ?? "<unknown role>"
                }
                    
                else if columnName == "name" {
                    if let subview = view?.subviews.first as? NSTextField {
                        subview.bind(NSBindingName(rawValue: "value"), to:entry, withKeyPath:"person.name", options: [:])
                    }
                }
            }
        }
        
        return view
    }
}
