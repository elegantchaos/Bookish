// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import Actions
import BookishModel

fileprivate var textBindingContext: Int = 0


class TextBinding<T>: NSObject {
    var target: T
    weak var source: NSObject?
    let path: String
    let setIfNull: Bool
    let transformer: ValueTransformer?
    
    init(for target: T, to source: NSObject, path: String, transformer: ValueTransformer? = nil, setIfNull: Bool = false) {
        self.target = target
        self.source = source
        self.path = path
        self.transformer = transformer
        self.setIfNull = setIfNull
        super.init()

        if let value = stringValue {
            boundText = value
        } else if setIfNull {
            boundText = ""
        }
        
        if path != "identifier" {
            source.addObserver(self, forKeyPath: path, options: [], context: &textBindingContext)
        }
        
    }
    
    deinit {
        if path != "identifier" {
            source?.removeObserver(self, forKeyPath: path, context: &textBindingContext)
        }
    }
    
    fileprivate var stringValue: String? {
        var value = source?.value(forKey: path)
        if let transformer = transformer {
            value = transformer.transformedValue(value)
        }
        return value as? String
    }
        
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let string = stringValue {
            boundText = string
        }
    }
    
    var boundText: String {
        get { return "" }
        set { }
    }
    
}

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

class StringBinding: TextBinding<NSObject> {
    let property: String
    init(for target: NSObject, property: String, to source: NSObject, path: String, setIfNull: Bool = false) {
        self.property = property
        super.init(for: target, to: source, path: path, setIfNull: setIfNull)
    }
    
    override var boundText: String {
        get { return target.value(forKey: property) as? String ?? "" }
        set(value) { target.setValue(value, forKey: property) }
    }
}

