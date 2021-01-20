// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Logger

let indexedListChannel = Channel("IndexedList")

protocol IndexedList where Value: Identifiable, Value: Codable, Value.ID: Codable  {
    associatedtype Value
    var order: [Value.ID] { get set }
    var index: [Value.ID:Value] { get set }
    init(order: [Value.ID], index: [Value.ID:Value])
    mutating func append(_ value: Value)
    mutating func move(fromOffsets from: IndexSet, toOffset to: Int)
    mutating func remove(itemWithID id: Value.ID)
    mutating func remove(at itemIndex: Int)
    mutating func remove(_ indices: IndexSet)
}

struct SimpleIndexedList<T>: IndexedList where T: Identifiable, T: Codable, T.ID: Codable {
    var order: [T.ID] = []
    var index: [T.ID:T] = [:]

    mutating func append(_ value: T) {
        order.append(value.id)
        index[value.id] = value
    }
    
    mutating func move(fromOffsets from: IndexSet, toOffset to: Int) {
        order.move(fromOffsets: from, toOffset: to)
    }
    
    mutating func remove(itemWithID id: T.ID) {
        index.removeValue(forKey: id)
        if let position = order.firstIndex(of: id) {
            order.remove(at: position)
        }
    }

    mutating func remove(at itemIndex: Int) {
        let id = order[itemIndex]
        order.remove(at: itemIndex)
        index.removeValue(forKey: id)
    }

    mutating func remove(_ indices: IndexSet) {
        for item in indices {
            remove(at: item)
        }
    }
}

