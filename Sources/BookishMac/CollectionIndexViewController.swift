// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Cocoa
import BookishModel

class CollectionIndexViewController: CollectionViewController {
    @objc weak var detailView: CollectionDetailViewController!
    @IBOutlet weak var indexArray: NSArrayController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: this is a bit naff as it makes assumptions about the containment hierarchy
        if let parent = self.parent as? NSSplitViewController {
            detailView = parent.splitViewItems[1].viewController as? CollectionDetailViewController
        }
    }
    
    override func viewWillAppear() {
        // we really should be able to bind the array to the object context in IB, but
        // the document value is set relatively late, so it's safer to do it here
//        if let context = document?.managedObjectContext {
//            indexArray.managedObjectContext = context
            indexArray.fetch(self)
//        }
//
        super.viewWillAppear()
    }
    
    @IBAction func insertPerson(_ sender: Any) {
        if let item = sender as? NSMenuItem  {
            if let type = item.identifier?.rawValue {
                if let selection = indexArray.selectedObjects as? [Book] {
                    for book in selection {
                        let context = cvm.managedObjectContext
                        let role = Role.role(named: type, context: context)
                        let entry = PersonEntry(context: context)
                        entry.person = Person(context: context)
                        entry.role = role
                        book.addToPeople(entry)
                    }
                }
            }
        }
    }

}
