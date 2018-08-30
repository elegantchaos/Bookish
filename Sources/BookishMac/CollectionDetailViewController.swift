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
    
    func peopleInSelection() -> (Set<PersonEntry>, Set<PersonEntry>) {
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
        }
        return (all, common)
    }
    
    func updatePeople() {
        let (_, common) = peopleInSelection()
        people = common.sorted(by: { ($0.person?.name ?? "") < ($1.person?.name ?? "") })
        detailsView.reloadData()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return rows.count + people.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var view: NSView? = nil
        if row < (rows.count + people.count), let columnID = tableColumn?.identifier {
            let columnName = columnID.rawValue
            view = tableView.makeView(withIdentifier: columnID, owner: self)
            let isPersonRow = row < people.count
            let index = isPersonRow ? row : row - people.count
            
            if columnName == "heading", let field = view as? NSTextField {
                if isPersonRow {
                    field.stringValue = people[index].role?.name ?? "<unknown role>"
                } else {
                    field.stringValue = rows[index].label
                }
            } else if columnName == "value", let subview = view?.subviews.first as? NSTextField {
                let bound: Any = isPersonRow ? people[index] : indexArray
                let path = isPersonRow ? "person.name" : "selection.\(rows[index].binding)"
                subview.bind(NSBindingName(rawValue: "value"), to:bound, withKeyPath:path, options: [:])
            }
        }
        
        return view
    }

    @IBAction func insertPerson(_ sender: Any) {
        if let item = sender as? NSMenuItem  {
            if let type = item.identifier?.rawValue {
                if let selection = indexArray.selectedObjects as? [Book] {
                    let context = cvm.managedObjectContext
                    let role = Role.role(named: type, context: context)
                    let entry = PersonEntry(context: context)
                    entry.person = Person(context: context)
                    entry.role = role
                    for book in selection {
                        book.addToPeople(entry)
                    }
                }
            }
            updatePeople()
        }
    }

}
