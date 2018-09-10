// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import AppKit

class ShowDatePickerAction: Action {
    override func perform(context: ActionContext) {
        if let view = context.sender as? NSView {
            let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
            if let contentController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Date Picker Controller")) as? DatePickerContentController {
                if let object = context.info["object"] as? NSObject, let binding = context.info["binding"] as? String {
                    contentController.representedObject = object
                    contentController.binding = binding
                    let popover = NSPopover()
                    popover.contentViewController = contentController
                    popover.show(relativeTo: view.bounds, of: view, preferredEdge: NSRectEdge.maxX)
                }
            }
        }
    }
}
