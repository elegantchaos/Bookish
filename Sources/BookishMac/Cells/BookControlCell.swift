// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/01/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import BookishModel
import AppKit

class BookControlCell: NSTableCellView, DetailTableCell {
    
    @IBOutlet weak var removeButton: NSButton!
    private var objectKey: String = ""
    
    func setup(for row: DetailItem, of view: DetailController) {
        if let (key, identifier, object) = row.removeAction {
            objectValue = object
            objectKey = key
            removeButton.identifier = NSUserInterfaceItemIdentifier(rawValue: identifier)
            removeButton.isHidden = false
        } else {
            removeButton.isHidden = true
        }
    }
    
    func keyView() -> NSView? {
        return nil
    }
}

extension BookControlCell: ActionContextProvider {
    func provide(context: ActionContext) {
        if let item = objectValue as? ModelObject, !objectKey.isEmpty {
            context[objectKey] = item
        }
    }
}
