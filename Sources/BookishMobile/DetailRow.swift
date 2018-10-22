// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel

var context: Int = 0

class TextBinding: NSObject, UITextViewDelegate {
    let target: UITextView
    let source: NSObject
    let path: String
    //    let observer: NSKeyValueObservation
    
    
    init(for target: UITextView, to source: NSObject, path: String) {
        self.target = target
        self.source = source
        self.path = path
        
        if let value = source.value(forKey: path) as? String {
            target.text = value
        }
//        if let value = value as? String {
//            target.setValue(value, forKey:property)
//        } else if let value = value as? NSValue {
//            target.setValue(value, forKey:property)
//        }
        
        //        observer = source.observe(path, changeHandler: { (index, change) in
        //            print(index)
        //            print(change)
        //        })
        
        super.init()

        target.delegate = self
        source.addObserver(self, forKeyPath: path, options: [], context: &context)
        
        //        observeValue(forKeyPath: path, of: source, change: nil, context: &context)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let string = source.value(forKey: path) as? String {
            target.text = string
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        source.setValue(target.text, forKey:path)
    }

}

@objc class Binding: NSObject {
    let target: Any
    let property: String
    let source: Any
    let path: String
//    let observer: NSKeyValueObservation
    

    init(for target: NSObject, property: String, to source: NSObject, path: String) {
        self.target = target
        self.property = property
        self.source = source
        self.path = path
        
        let value = source.value(forKey: path)
        if let value = value as? String {
            target.setValue(value, forKey:property)
        } else if let value = value as? NSValue {
            target.setValue(value, forKey:property)
        }
        
//        observer = source.observe(path, changeHandler: { (index, change) in
//            print(index)
//            print(change)
//        })
        
        super.init()
        
        target.addObserver(self, forKeyPath: path, options: [], context: &context)
        
//        observeValue(forKeyPath: path, of: source, change: nil, context: &context)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print(change)
    }
}

class DetailRow: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var detail: UITextView!
    
    var binding: TextBinding?
    
    func setup(row: Int, book: Book, source: DetailDataSource) {
        assert(!source.info(for: row).isPerson)
        let rowInfo = source.details(for: row)
        label.text = rowInfo.label
        binding = TextBinding(for: detail, to: book, path: rowInfo.binding)
////        detail.text = book.value(forKey: rowInfo.binding) as? String
//        detail.bind(NSBindingName(rawValue: "text"), to:book, withKeyPath:rowInfo.binding, options: [])
    }
}
