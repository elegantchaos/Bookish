// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel
import Actions

class BookIndexViewController: CollectionViewController {
    @objc weak var detailView: BookDetailViewController!
    @IBOutlet weak var indexArray: NSArrayController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: this is a bit naff as it makes assumptions about the containment hierarchy
        if let parent = self.parent as? NSSplitViewController {
            detailView = parent.splitViewItems[1].viewController as? BookDetailViewController
        }
    }
    
    override func viewWillAppear() {
        if let window = view.window?.windowController as? CollectionWindowController {
            window.bookIndexController = self
        }
        // we really should be able to bind the array to the object context in IB, but
        // the document value is set relatively late, so it's safer to do it here
//        if let context = document?.managedObjectContext {
//            indexArray.managedObjectContext = context
            indexArray.fetch(self)
//        }
//
        super.viewWillAppear()
    }
    
    func validatableItems(for view: NSView) -> [NSValidatedUserInterfaceItem] {
        var items = [NSValidatedUserInterfaceItem]()
        if let viewItem = view as? NSValidatedUserInterfaceItem {
            items.append(viewItem)
        }
        for subview in view.subviews {
            if let subviewItem = subview as? NSValidatedUserInterfaceItem {
                items.append(subviewItem)
            }
        }
        
        return items
    }
    
    func validateButtons() {
        let items = validatableItems(for: view)
        for item in items {
            if let button = item as? NSButton, let action = button.action {
                if let validator = NSApp.target(forAction: action, to: nil, from: item) as? NSUserInterfaceValidations {
                    button.isEnabled = validator.validateUserInterfaceItem(item)
                }
            }
        }
    }
}

extension BookIndexViewController: ActionContextProvider {
    func provide(context: ActionContext) {
        detailView.provide(context: context)
    }
}
