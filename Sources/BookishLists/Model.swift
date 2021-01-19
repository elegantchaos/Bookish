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

typealias BookListIndex = SimpleIndexedList<BookList>
typealias BookIndex = SimpleIndexedList<Book>

extension IndexedList {
    static func load(from store: ObjectStore, idKey id: String, completion: @escaping (Result<Self,Error>) -> ()) where Value.ID == String {
        store.load([String].self, withId: id) { result in
            switch result {
                case let .failure(error):
                    completion(.failure(error))

                case let .success(ids):
                    store.load(Value.self, withIds: ids) { objects, errors in
                        var index: [Value.ID:Value] = [:]
                        for object in objects {
                            index[object.id] = object
                        }
                        completion(.success(Self(order: ids, index: index)))
                    }
            }
        }
    }
    
    func save(to store: ObjectStore, idKey id: String) where Value.ID == String {
        store.save(order, withId: id) { result in
            switch result {
                case let .failure(error): print(error) // TODO: handle this properly
                case .success:
                    store.save(Array(index.values)) { results in
                        
                    }
            }
        }
    }
}

class Model: ObservableObject {
    @Published var books = BookIndex()
    @Published var lists = BookListIndex()

    init() {
    }
    
    init(from store: ObjectStore) {
        migrate(from: store)
        loadBooks(store: store)
    }
    
    func loadBooks(store: ObjectStore) {
        BookIndex.load(from: store, idKey: .booksKey) { result in
            switch result {
                case let .success(index):
                    self.books = index
                    self.loadLists(store: store)
                    
                case let .failure(error):
                    print(error)
            }
        }
    }

    func loadLists(store: ObjectStore) {
        BookListIndex.load(from: store, idKey: .listsKey) { result in
            switch result {
                case let .success(index):
                    self.lists = index
                    self.normaliseData()
                    
                case let .failure(error):
                    print(error)
            }
        }
    }
    
    func normaliseData() {
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
        lists.save(to: store, idKey: .listsKey)
        books.save(to: store, idKey: .booksKey)
    }

    func binding(forBookList id: BookList.ID) -> Binding<BookList> {
        Binding<BookList>(
            get: { self.lists.index[id] ?? BookList(id: id, name: "<mising>", entries: [], values: [:]) },
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
