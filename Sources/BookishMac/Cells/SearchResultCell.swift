// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 30/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class SearchResultCell: NSTableCellView {
    
    @IBOutlet weak var coverView: NSImageView!
    @IBOutlet weak var titleField: NSTextField!
    @IBOutlet weak var authorsField: NSTextField!
    @IBOutlet weak var publisherField: NSTextField!
    @IBOutlet weak var actionButton: NSButton!
    
    func setup(for object: ModelEntityCommon) {
        objectValue = object
        if let name = object.name {
            titleField.stringValue = name
        }
        //
        //        actionButton.identifier = NSUserInterfaceItemIdentifier(rawValue: candidate.action)
        application.actionManager.validateControls(of: actionButton)
        object.setImage(for: coverView, cache: application.imageCache)
    }
}

extension SearchResultCell: ActionContextProvider {
    func provide(context: ActionContext) {
        context[ActionContext.objectKey] = objectValue
    }
}
