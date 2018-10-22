// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit

fileprivate var textBindingContext: Int = 0

protocol TextBindable {
    var boundText: String? { get set }
    func connectDelegate(binding: Any)
}

class TextBinding<T>: NSObject, UITextViewDelegate, UITextFieldDelegate where T: TextBindable {
    var target: T
    let source: NSObject
    let path: String
    
    init(for target: T, to source: NSObject, path: String) {
        self.target = target
        self.source = source
        self.path = path
        super.init()
        
        if let value = source.value(forKey: path) as? String {
            self.target.boundText = value
        }
        
        self.target.connectDelegate(binding: self)
//        self.target.delegate = self
        source.addObserver(self, forKeyPath: path, options: [], context: &textBindingContext)
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let string = source.value(forKey: path) as? String {
            target.boundText = string
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        source.setValue(target.boundText, forKey:path)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        source.setValue(target.boundText, forKey:path)
    }
}

extension UITextView: TextBindable {
    var boundText: String? {
        get { return self.text }
        set(value) { self.text = value }
    }
    
    func connectDelegate(binding: Any) {
        if let delegate = binding as? UITextViewDelegate {
            self.delegate = delegate
        }
    }
}

extension UITextField: TextBindable {
    var boundText: String? {
        get { return self.text }
        set(value) { self.text = value }
    }
    
    func connectDelegate(binding: Any) {
        if let delegate = binding as? UITextFieldDelegate {
            self.delegate = delegate
        }
    }
}
