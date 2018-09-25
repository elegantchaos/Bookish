// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishCore
import BookishModel

class CollectionWindowController: NSWindowController, DocumentWindowController, ActionContextProvider, NSUserInterfaceValidations {
    var viewModel: CollectionDocumentViewModel?
    typealias ViewModel = CollectionDocumentViewModel
    
    var bookIndexController: BookIndexViewController?
    var bookDetailController: BookDetailViewController?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.autorecalculatesKeyViewLoop = false
    }
    
    func provide(context: ActionContext) {
        if let model = viewModel {
            context.info[ActionContext.modelKey] = model
        }
    }
    
    func validatableItems(for view: NSView) -> [NSControl] {
        var items = [NSControl]()
        if let viewItem = view as? NSControl {
            items.append(viewItem)
        }
        for subview in view.subviews {
            if !subview.isHidden {
                items.append(contentsOf: validatableItems(for: subview))
            }
        }
        
        return items
    }
    
    func validateButtons() {
        let actionManager = Application.sharedInstance.actionManager
        if let view = window?.contentView {
            let items = validatableItems(for: view)
            for item in items {
                if let button = item as? NSButton, let identifier = item.identifier?.rawValue {
                    button.isEnabled = actionManager.validate(identifier: identifier, item: button)
                }
            }
        }
    }
}
