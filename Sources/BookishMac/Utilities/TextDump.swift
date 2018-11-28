// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/11/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

class TextDump {
    class func sanitize(_ dict: [String:Any]) -> [String:Any ]{
        var sanitized = [String:Any]()
        for item in dict {
            let value: Any
            if JSONSerialization.isValidJSONObject(item.value) {
                value = item.value
            } else if let subdict = item.value as? [String:Any] {
                value = sanitize(subdict)
            } else {
                value = "\(item.value)"
            }
            sanitized[item.key] = value
        }
        return sanitized
    }
    
    class func dump(_ dict: [String:Any]) -> String {
        let sanitzed = sanitize(dict)
        if let data = try? JSONSerialization.data(withJSONObject: sanitzed, options: [.prettyPrinted, .sortedKeys])  {
            if let encoded = String(data: data, encoding: .utf8) {
                return encoded
            }
        }
        
        return dict.description
    }

    class func sanitized(_ value: Any) -> Any {
        let result: Any
        if let nsvalue = value as? NSValue {
            result = nsvalue
        } else if let subdict = value as? Dictionary<String, Any> {
            result = subdict.sanitize()
        } else if let array = value as? Array<Any> {
            result = array.sanitize()
        } else {
            result = "\(value)"
        }
        return result
    }

}



extension Array {
    func sanitize() -> Array<Any> {
        var sanitized = Array<Any>()
        for item in self {
            sanitized.append(TextDump.sanitized(item))
        }
        return sanitized
    }

}

extension Dictionary {
    func jsonDump() -> String {
        let sanitzed = self.sanitize()
        if let data = try? JSONSerialization.data(withJSONObject: sanitzed, options: [.prettyPrinted, .sortedKeys])  {
            if let encoded = String(data: data, encoding: .utf8) {
                return encoded
            }
        }
        
        return self.description
    }

    func sanitize() -> Dictionary<String, Any> {
        var sanitized = Dictionary<String, Any>()
        for item in self {
            if let key = item.key as? String {
                let value: Any
                if let subdict = item.value as? Dictionary<Key, Any> {
                    value = subdict.sanitize()
                } else {
                    value = TextDump.sanitized(item.value)
                }
                sanitized[key] = value
            }
        }
        return sanitized
    }

}
