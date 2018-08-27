// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Cocoa
import BookishModel

class CollectionDetailViewController: CollectionViewController, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet weak var indexView: CollectionIndexViewController!
    @IBOutlet weak var indexArray: NSArrayController!
    
    let headings = ["Name", "Summary"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: this is a bit naff as it makes assumptions about the containment hierarchy
        if let parent = self.parent as? NSSplitViewController {
            indexView = parent.splitViewItems[0].viewController as? CollectionIndexViewController
        }
    }
    
    override func viewWillAppear() {
        // we really should be able to bind the array to the object context in IB, but
        // the document value is set relatively late, so it's safer to do it here
//        if let context = document?.managedObjectContext {
//            indexArray.managedObjectContext = context
            indexArray.fetch(self)
//        }

        super.viewWillAppear()
    }
 
    func numberOfRows(in tableView: NSTableView) -> Int {
        return headings.count
    }
    
    @objc func blah() -> String {
        return "blah"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if row < headings.count {
            let heading = headings[row]
            let column = tableColumn?.identifier.rawValue
            if column == "heading" {
                let view = NSTextField(frame: NSZeroRect)
                view.stringValue = heading
                return view
            }
            
            else if column == "value" {
                let view = NSTextField(frame: NSZeroRect)
                view.bind(NSBindingName(rawValue: "value"), to:indexArray, withKeyPath:"selection.\(heading.lowercased())", options: [:])
                return view
            }
        }
        
        return nil
    }
}
