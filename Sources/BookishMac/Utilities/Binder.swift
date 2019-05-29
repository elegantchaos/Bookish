// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 29/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import BookishModel
import Logger

fileprivate var binderContext: Int = 0

let binderChannel = Logger("Binder")

enum BoundValue {
    case noSelection
    case multipleValues
    case value(value: Any?, source: Any?)
}

class Binder: NSObject {
    let target: Any
    let property: String
    let source: BoundValue
    let actionManager: ActionManager
    let transformer: ValueTransformer?
    
    init(target: Any, property: String, source: BoundValue, actionManager: ActionManager, transformer: ValueTransformer? = nil) {
        binderChannel.debug("Bound \(target) to \(property)")
        self.target = target
        self.property = property
        self.source = source
        self.actionManager = actionManager
        self.transformer = transformer
        super.init()
        
        connect()
        switch source {
        case .noSelection:
            setEmpty()
            
        case .multipleValues:
            setMultiple()
            
        case .value(let value, let source):
            set(untransformedValue: value)
            if let object = source as? NSObject {
                object.addObserver(self, forKeyPath: property, options: [], context: &binderContext)
            }
        }
    }
    
    convenience init(target: Any, property: String, source: BoundValue, actionManager: ActionManager, transformer transformerName: String) {
        let transformer = ValueTransformer(forName: NSValueTransformerName(rawValue: transformerName))
        self.init(target: target, property: property, source: source, actionManager: actionManager, transformer: transformer)
    }
    
    deinit {
        disconnect()
        switch source {
        case .value(_, let source):
            if let object = source as? NSObject {
                object.removeObserver(self, forKeyPath: property, context: &binderContext)
            }
        default:
            break
        }
        binderChannel.debug("Unbound \(target) from \(property)")
    }
    
    func connect() {
    }
    
    func disconnect() {
    }
    
    func set(untransformedValue: Any?) {
        let value = transformer == nil ? untransformedValue : transformer!.transformedValue(untransformedValue)
        if let value = value {
            set(value: value)
        } else {
            setEmpty()
        }
    }
    
    func set(value: Any) {
    }
    
    func setMultiple() {
    }
    
    func setEmpty() {
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &binderContext {
            let value = (object as? NSObject)?.value(forKey: property)
            set(untransformedValue: value)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
}

class TypedBinder<T, V: Equatable>: Binder {
    var current: V?
    var typedTarget: T { return target as! T }
    
    init(target: T, property: String, source: BoundValue, actionManager: ActionManager, transformer: ValueTransformer? = nil) {
        super.init(target: target, property: property, source: source, actionManager: actionManager, transformer: transformer)
    }
    
    override func set(value: Any) {
        if let value = value as? V {
            if value != current {
                current = value
                set(value: value)
            }
        } else {
            setEmpty()
        }
    }
    func set(value: V) {
    }
    
    func changed(newValue: V) {
        if current != newValue {
            current = newValue
            let transformed = transformer == nil ? newValue : transformer!.reverseTransformedValue(newValue)!
            ChangeValueAction.send("ChangeValue", from: target, manager: actionManager, property: property, value: transformed)
        }
    }
}
