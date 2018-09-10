// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

class DatePickerPopoverController: NSViewController, NSPopoverDelegate {
    @IBOutlet private var datePicker: NSDatePicker!
    private var valueKey: String = ""
    
    static func show(for view: NSView, object: NSObject, key: String) {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        if let contentController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Date Picker Controller")) as? DatePickerPopoverController {
            contentController.representedObject = object
            contentController.valueKey = key
            let popover = NSPopover()
            popover.delegate = contentController
            popover.contentViewController = contentController
            popover.behavior = .semitransient
            popover.show(relativeTo: view.bounds, of: view, preferredEdge: NSRectEdge.maxX)
        }
    }
    
    func popoverWillShow(_ notification: Notification) {
        if let object = representedObject as? NSObject, let date = object.value(forKey: valueKey) as? Date {
            datePicker.dateValue = date
        }
    }
    
    @IBAction func dateChanged(_ sender: Any) {
        if let object = representedObject as? NSObject {
            object.setValue(datePicker.dateValue, forKey: valueKey)
        }
    }
}
