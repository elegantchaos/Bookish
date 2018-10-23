// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit

fileprivate var textBindingContext: Int = 0

class TextBinding<T>: NSObject {
    var target: T
    let source: NSObject
    let path: String
    
    init(for target: T, to source: NSObject, path: String) {
        self.target = target
        self.source = source
        self.path = path
        super.init()
        
        if let value = source.value(forKey: path) as? String {
            boundText = value
        }
        
        connectDelegate()
        source.addObserver(self, forKeyPath: path, options: [], context: &textBindingContext)
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let string = source.value(forKey: path) as? String {
            boundText = string
        }
    }
    
    var boundText: String {
        get { return "" }
        set { }
    }
    
    func connectDelegate() {
    }
    
}

class TextViewBinding: TextBinding<UITextView>, UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        source.setValue(target.text, forKey:path)
    }
    
    override func connectDelegate() {
        target.delegate = self
    }
    
    override var boundText: String {
        get { return target.text }
        set(value) { target.text = value }
    }
}

class TextFieldBinding: TextBinding<UITextField>, UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        source.setValue(target.text, forKey:path)
    }

    override func connectDelegate() {
        target.delegate = self
    }
    
    override var boundText: String {
        get { return target.text ?? "" }
        set(value) { target.text = value }
    }
}

class StringBinding: TextBinding<NSObject> {
    let property: String
    init(for target: NSObject, property: String, to source: NSObject, path: String) {
        self.property = property
        super.init(for: target, to: source, path: path)
    }
    
    override var boundText: String {
        get { return target.value(forKey: property) as? String ?? "" }
        set(value) { target.setValue(value, forKey: property) }
    }
}

