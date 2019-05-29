// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 29/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit

class TextViewBinding: TextBinding<UITextView>, UITextViewDelegate {
    override init(for target: UITextView, to source: NSObject, path: String, transformer: ValueTransformer? = nil, setIfNull: Bool = false) {
        super.init(for: target, to: source, path: path, transformer: transformer, setIfNull: setIfNull)
        target.delegate = self
    }
    
    deinit {
        target.delegate = nil
    }
    
    override var boundText: String {
        get { return target.text }
        set(value) { target.text = value }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        ChangeValueAction.send("ChangeValue", from: textView, manager: textView.application.actionManager, property: path, value: target.text, to: source)
    }
}

class TextFieldBinding: TextBinding<UITextField>, UITextFieldDelegate {
    override init(for target: UITextField, to source: NSObject, path: String, transformer: ValueTransformer? = nil, setIfNull: Bool = false) {
        super.init(for: target, to: source, path: path, transformer: transformer, setIfNull: setIfNull)
        target.delegate = self
    }
    
    deinit {
        target.delegate = nil
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        ChangeValueAction.send("ChangeValue", from: textField, manager: textField.application.actionManager, property: path, value: target.text as Any, to: source)
    }
    
    override var boundText: String {
        get { return target.text ?? "" }
        set(value) { target.text = value }
    }
}
