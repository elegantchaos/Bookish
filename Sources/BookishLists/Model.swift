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

protocol IndexedList where Value: Identifiable, Value: Codable  {
    associatedtype Value
    var order: [Value.ID] { get set }
    var index: [Value.ID:Value] { get set }
    mutating func append(_ value: Value)
}

struct SimpleIndexedList<T>: IndexedList where T: Identifiable, T: Codable {
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
    mutating func load(from store: KeyValueStore, with decoder: JSONDecoder, idKey: String) {
        var raw: [Value] = []
        raw.load(from: store, with: decoder, idKey: idKey)
        for value in raw {
            let id = value.id
            order.append(id)
            index[id] = value
        }
    }
    
    func save(to store: KeyValueStore, with encoder: JSONEncoder, idKey: String) {
        store.set(order, forKey: idKey)
        let raw = Array(index.values)
        raw.save(to: store, with: encoder)
    }
}

class Model: ObservableObject {
    @Published var books = BookIndex()
    @Published var lists = BookListIndex()

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

    func binding(forBookList id: BookList.ID) -> Binding<BookList> {
        Binding<BookList>(
            get: { self.lists.index[id]! },
            set: { newValue in self.lists.index[id] = newValue }
        )
    }

    func binding(forBook id: Book.ID) -> Binding<Book> {
        Binding<Book>(
            get: { self.books.index[id]! },
            set: { newValue in self.books.index[id] = newValue }
        )
    }
}
