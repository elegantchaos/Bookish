// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import KeyValueStore

extension String {
    static let booksKey = "Books"
    static let listsKey = "Lists"
}

struct Book: Identifiable, Codable {
    let id: UUID
    let name: String
}

struct BookList: Identifiable, Codable {
    let id: UUID
    var name: String
    let entries: [UUID]
    let values: [UUID:String]
}

protocol OrderedList where Value: Identifiable, Value: Codable {
    associatedtype Value
    var order: [Value.ID] { get set }
    var values: [Value.ID:Value] { get set }
}

struct OrderedBooks: OrderedList {
    var order: [UUID] = []
    var values: [UUID:Book] = [:]
}

struct OrderedBookLists: OrderedList {
    var order: [UUID] = []
    var values: [UUID:BookList] = [:]
}


extension OrderedList {
    mutating func load(from store: KeyValueStore, with decoder: JSONDecoder, idKey: String) {
        var raw: [Value] = []
        raw.load(from: store, with: decoder, idKey: idKey)
        for value in raw {
            let id = value.id
            order.append(id)
            values[id] = value
        }
    }
    
    func save(to store: KeyValueStore, with encoder: JSONEncoder, idKey: String) {
        store.set(order, forKey: idKey)
        let raw = Array(values.values)
        raw.save(to: store, with: encoder)
    }
}

class Model: ObservableObject {
    @Published var books = OrderedBooks()
    @Published var lists = OrderedBookLists()

    init() {
    }
    
    init(from store: KeyValueStore) {
        let decoder = JSONDecoder()
        
        lists.load(from: store, with: decoder, idKey: .listsKey)
        books.load(from: store, with: decoder, idKey: .booksKey)
        
        migrate(from: store)
        
    }
    
    var appName: String { "Bookish Lists" }
    
    func migrate(from store: KeyValueStore) {
    }
    
    func save(to store: KeyValueStore) {
        let encoder = JSONEncoder()
        lists.save(to: store, with: encoder, idKey: .listsKey)
        books.save(to: store, with: encoder, idKey: .booksKey)
    }

    func binding(forBook id: UUID) -> Binding<BookList> {
        Binding<BookList>(
            get: { self.lists.values[id]! },
            set: { newValue in self.lists.values[id] = newValue }
        )
    }
}
