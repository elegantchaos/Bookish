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

        // ensure that the table is populated
        indexArray.fetch(self)
    }
 
    func numberOfRows(in tableView: NSTableView) -> Int {
        return rows.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var view: NSView? = nil
        if row < rows.count, let columnID = tableColumn?.identifier {
            let columnName = columnID.rawValue
            let rowSpec = rows[row]
            view = tableView.makeView(withIdentifier: columnID, owner: self)
            if columnName == "heading", let field = view as? NSTextField {
                field.stringValue = rowSpec.label
            }
                
            else if columnName == "value" {
                view?.bind(NSBindingName(rawValue: "objectValue"), to:indexArray, withKeyPath:"selection.\(rowSpec.binding)", options: [:])
            }
        }
        
        return view
    }
}
