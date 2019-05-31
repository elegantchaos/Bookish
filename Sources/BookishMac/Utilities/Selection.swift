// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 29/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel

class Selection<T: NSObject> {
    var objects: [T] = []
    
    var count: Int {
        return objects.count
    }
    
    func value(forKey key: String) -> BoundValue {
        switch objects.count {
        case 0:
            return .noSelection
        case 1:
            let object = objects.first!
            let value = object.value(forKey: key)
            return .value(value: value, source: object)
        default:
            let value = objects.first!.value(forKey: key) as? NSObject
            for item in objects {
                let nextValue = item.value(forKey: key) as? NSObject
                if nextValue != value {
                    return .multipleValues
                }
            }
            return .value(value: value, source: nil)
        }
    }

    func singleValue(forKey key: String) -> Any? {
        let value = self.value(forKey: key)
        switch value {
        case .value(let value):
            return value
        default:
            return nil
        }
    }

    func proxy(withUniformKeys keys: [String]) -> Any? {
        for key in keys {
            let value = self.value(forKey: key)
            switch value {
            case .value(_, let object):
                return object
            default:
                break
            }
        }
        return nil
    }
    
    func set(from indexes: IndexSet, of allObjects: [T]) {
        objects.removeAll()
        for index in indexes {
            objects.append(allObjects[index])
        }
    }
    
    func indexes(in allObjects: [T]) -> IndexSet {
        var indexes = IndexSet()
        for object in objects {
            if let index = allObjects.firstIndex(of: object) {
                indexes.insert(index)
            }
        }
        return indexes
    }
}
