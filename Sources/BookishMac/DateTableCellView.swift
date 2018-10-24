// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class DateTableCellView: AnnotatedTableCellView, ActionContextProvider {
    @IBOutlet weak var infoButton: NSButton!
    var binding: String = ""
    
    override var annotationButtons: [NSButton] {
        return [infoButton]
    }
    
    func provide(context: ActionContext) {
        context.info["object"] = objectValue
        context.info["binding"] = binding
    }

}
