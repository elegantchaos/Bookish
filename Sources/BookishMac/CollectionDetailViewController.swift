// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Cocoa
import BookishModel

enum RowType {
    case text
    case date
    case dateReadOnly
}

struct RowSpecification {
    let binding: String
    let label: String
    let type: RowType
    
    init(binding: String, label: String? = nil, type: RowType = .text) {
        self.binding = binding
        self.label = label ?? binding
        self.type = type
    }
}

class CollectionDetailViewController: CollectionViewController, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet weak var indexView: CollectionIndexViewController!
    @IBOutlet weak var indexArray: NSArrayController!
    @IBOutlet weak var detailsView: NSTableView!
    
    var people = [PersonRole]()
    var indexObserver: NSKeyValueObservation?
    var dateViewID = NSUserInterfaceItemIdentifier(rawValue: "")
    
    let rows = [
        RowSpecification(binding: "format"),
        RowSpecification(binding: "isbn"),
        RowSpecification(binding: "notes"),
        RowSpecification(binding: "published", type: .date),
        RowSpecification(binding: "added", type: .dateReadOnly),
        RowSpecification(binding: "modified", type: .date)
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
    
    func peopleInSelection() -> (Set<PersonRole>, Set<PersonRole>) {
        var all = Set<PersonRole>()
        var common = Set<PersonRole>()
        if let selection = indexArray.selectedObjects as? [Book] {
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
            var viewID = columnID
            let isPersonRow = row < people.count
            let index = isPersonRow ? row : row - people.count
            if !isPersonRow && (columnName == "value") && rows[index].type == .date {
                viewID = NSUserInterfaceItemIdentifier(rawValue: "date")
            }
            view = tableView.makeView(withIdentifier: viewID, owner: self)
            
            if columnName == "heading", let field = view?.subviews.first as? NSTextField {
                if isPersonRow {
                    field.stringValue = people[index].role?.name ?? "<unknown role>"
                } else {
                    field.stringValue = rows[index].label
                }
            } else if columnName == "value", let subview = view?.subviews.first {
                var options = [NSBindingOption:Any]()
                if !isPersonRow && (rows[index].type == .dateReadOnly) {
                    options[NSBindingOption(rawValue: "NSValueTransformer")] = ValueTransformer(forName: NSValueTransformerName(rawValue: "DateToString"))
                }
                let bound: Any = isPersonRow ? people[index] : indexArray
                let path = isPersonRow ? "person.name" : "selection.\(rows[index].binding)"
                subview.bind(NSBindingName(rawValue: "value"), to:bound, withKeyPath:path, options: options)
            }
        }
        
        return view
    }

    @IBAction func insertPerson(_ sender: Any) {
        if let item = sender as? NSMenuItem  {
            if let roleName = item.identifier?.rawValue {
                if let selection = indexArray.selectedObjects as? [Book] {
                    let context = cvm.managedObjectContext
                    let person = Person(context: context)
                    let role = person.role(as: roleName)
                    for book in selection {
                        book.addToPersonRoles(role)
                    }
                }
            }
            updatePeople()
        }
    }

}
