// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 29/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class NSTextFieldBinder: TypedBinder<NSTextField, String>, NSTextFieldDelegate {
    let hideIfEmpty: Bool
    
    init(target: NSTextField, property: String, source: BoundValue, actionManager: ActionManager, transformer: ValueTransformer? = nil, hideIfEmpty: Bool = false) {
        self.hideIfEmpty = hideIfEmpty
        super.init(target: target, property: property, source: source, actionManager: actionManager, transformer: transformer)
    }
    
    override func setEmpty() {
        typedTarget.stringValue = ""
        typedTarget.placeholderString = nil
        typedTarget.isHidden = hideIfEmpty
    }
    
    override func setMultiple() {
        typedTarget.stringValue = ""
        typedTarget.placeholderString = "Multiple values"
        typedTarget.isHidden = false
    }
    
    override func set(value: String) {
        typedTarget.stringValue = value
        typedTarget.isHidden = false
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
