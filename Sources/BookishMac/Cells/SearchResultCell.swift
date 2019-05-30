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
    
    func setup(for object: ModelObject) {
        objectValue = object
        if let name = object.value(forKey: "name") as? String {
            titleField.stringValue = name
        }
        //
        //        actionButton.identifier = NSUserInterfaceItemIdentifier(rawValue: candidate.action)
        application.actionManager.validateControls(of: actionButton)
        if let data = object.value(forKey: "image") as? Data, let image = NSImage(data: data) {
            coverView.image = image
        } else {
            coverView.image = NSImage(named: type(of:object).entityPlaceholder)
            if let urlString = object.value(forKey: "imageURL") as? String, let url = URL(string: urlString) {
                application.imageCache.image(for: url) { (image) in
                    self.coverView.image = image
                }
            }
        }
    }
}

extension SearchResultCell: ActionContextProvider {
    func provide(context: ActionContext) {
        context[ActionContext.objectKey] = objectValue
    }
}
