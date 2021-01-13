// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import KeyValueStore
import ObjectStore
import SwiftUI

extension String {
    static let booksKey = "Books"
    static let listsKey = "Lists"
}

struct Book: Identifiable, Codable {
    let id: String
    var name: String
}

struct BookList: Identifiable, Codable {
    let id: String
    var name: String
    var entries: [BookList.ID]
    var values: [BookList.ID:String]
}

protocol JSONCodable {
    static func decode(fromJSONCoding string: String) -> Self
    var encodeAsJSON: String { get }
}

extension UUID: JSONCodable {
    static func decode(fromJSONCoding string: String) -> UUID {
        UUID(uuidString: string) ?? UUID()
    }
    
    var encodeAsJSON: String {
        self.uuidString
    }
}

protocol IndexedList where Value: Identifiable, Value: Codable, Value.ID: Codable  {
    associatedtype Value
    var order: [Value.ID] { get set }
    var index: [Value.ID:Value] { get set }
    mutating func append(_ value: Value)
}

struct SimpleIndexedList<T>: IndexedList where T: Identifiable, T: Codable, T.ID: Codable {
    var order: [T.ID] = []
    var index: [T.ID:T] = [:]

    mutating func append(_ value: T) {
        order.append(value.id)
        index[value.id] = value
    }
}

typealias BookListIndex = SimpleIndexedList<BookList>
typealias BookIndex = SimpleIndexedList<Book>

extension IndexedList {
    mutating func load(from store: ObjectStore, with decoder: JSONDecoder, idKey id: String) where Value.ID == String {
        if let ids = store.load([String].self, withId: id), let objects = store.load(Value.self, withIds: ids) {
            order = ids
            for object in objects {
                index[object.id] = object
            }
        }
    }
    
    func save(to store: ObjectStore, with encoder: JSONEncoder, idKey id: String) where Value.ID == String {
        store.save(order, withId: id)
        store.save(Array(index.values))
    }
}

class Model: ObservableObject {
    @Published var books = BookIndex()
    @Published var lists = BookListIndex()

    init() {
    }
    
    init(from store: ObjectStore) {
        let decoder = JSONDecoder()
        
        lists.load(from: store, with: decoder, idKey: .listsKey)
        books.load(from: store, with: decoder, idKey: .booksKey)
        
        migrate(from: store)
        
        let allBooks = Set(books.index.keys)
        let allLists = lists.index.values
        for list in allLists {
            let entries = Set(list.entries)
            let normalised = entries.intersection(allBooks)
            if normalised.count < entries.count {
                var updated = list
                updated.entries = Array(normalised)
                lists.index[list.id] = updated
                print("Removed some missing entries for \(list.name)")
            }
        }
    }
    
    var appName: String { "Bookish Lists" }
    
    func migrate(from store: ObjectStore) {
    }
    
    func save(to store: ObjectStore) {
        let encoder = JSONEncoder()
        lists.save(to: store, with: encoder, idKey: .listsKey)
        books.save(to: store, with: encoder, idKey: .booksKey)
    }

    func binding(forBookList id: BookList.ID) -> Binding<BookList> {
        Binding<BookList>(
            get: { self.lists.index[id]! },
            set: { newValue in self.lists.index[id] = newValue }
        )
    }

    func binding(forBook id: Book.ID) -> Binding<Book> {
        Binding<Book>(
            get: { self.books.index[id] ?? Book(id: id, name: "<missing>") },
            set: { newValue in self.books.index[id] = newValue }
        )
    }
}
