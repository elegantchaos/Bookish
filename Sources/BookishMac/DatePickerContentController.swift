// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

class DatePickerContentController: NSViewController, NSPopoverDelegate {
    @IBOutlet var datePicker: NSDatePicker!
    var binding: String = ""
    
    func popoverWillShow(_ notification: Notification) {
        if let object = representedObject as? NSObject {
            var options = [NSBindingOption:Any]()
            options[NSBindingOption.continuouslyUpdatesValue] = true
            datePicker.bind(NSBindingName(rawValue: "value"), to:object, withKeyPath:"self.\(binding)", options: options)
        }
    }
    
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        return true
    }
    
    @IBAction func dateChanged(_ sender: Any) {
        if let object = representedObject as? NSObject {
            object.setValue(datePicker.dateValue, forKey: binding)
        }
    }
}
