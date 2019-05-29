// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 29/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class TextViewBinding: TextBinding<NSTextView>, NSTextViewDelegate {
    let actionManager: ActionManager
    
    init(for target: NSTextView, to source: NSObject, path: String, transformer: ValueTransformer? = nil, setIfNull: Bool = false, actionManager: ActionManager) {
        self.actionManager = actionManager
        super.init(for: target, to: source, path: path, transformer: transformer, setIfNull: setIfNull)
        target.delegate = self
    }
    
    deinit {
        target.delegate = nil
    }
    
    override var boundText: String {
        get { return target.string }
        set(value) { target.string = value }
    }
    
    func textDidChange(_ notification: Notification) {
        ChangeValueAction.send("ChangeValue", from: target, manager: actionManager, property: path, value: target.string)
    }
}
