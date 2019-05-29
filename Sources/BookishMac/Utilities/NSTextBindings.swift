// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 29/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class NSTextFieldBinder: TypedBinder<NSTextField, String>, NSTextFieldDelegate {
    override func setEmpty() {
        typedTarget.stringValue = ""
        typedTarget.placeholderString = nil
    }
    
    override func setMultiple() {
        typedTarget.stringValue = ""
        typedTarget.placeholderString = "Multiple values"
    }
    
    override func set(value: String) {
        typedTarget.stringValue = value
    }
    
    override func connect() {
        typedTarget.delegate = self
    }
    
    override func disconnect() {
        typedTarget.delegate = nil
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        changed(newValue: typedTarget.stringValue)
    }
}
