// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

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
