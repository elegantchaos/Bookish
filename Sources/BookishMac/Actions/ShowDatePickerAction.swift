// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import AppKit

class ShowDatePickerAction: Action {
    override func perform(context: ActionContext) {
        if
            let view = context.sender as? NSView,
            let object = context.info["object"] as? NSObject,
            let binding = context.info["binding"] as? String {
                DatePickerPopoverController.show(for: view, object: object, key: binding)
        }
    }
}
