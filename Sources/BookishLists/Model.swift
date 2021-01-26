// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import KeyValueStore
import Logger
import ObjectStore
import SwiftUI

let modelChannel = Channel("Model")

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

typealias BookListIndex = SimpleIndexedList<BookList>
typealias BookIndex = SimpleIndexedList<Book>

class Model: ObservableObject {
    var loaded = false
    @Published var books = BookIndex()
    @Published var lists = BookListIndex()

    init() {
    }
    
    init(from store: ObjectStore) {
//        migrate(from: store)
//        loadBooks(store: store)
    }
    
    func loadBooks(store: ObjectStore) {
        modelChannel.log("Loading books")
        BookIndex.load(from: store, idKey: .booksKey) { result in
            print("blah")
            switch result {
                case let .success(index):
                    self.books = index
                    self.loadLists(store: store)
                    
                case let .failure(error):
                    modelChannel.log("Loading books failed: \(error)")
                    self.loaded = true
            }
        }
    }

    func loadLists(store: ObjectStore) {
        modelChannel.log("Loading lists")
        BookListIndex.load(from: store, idKey: .listsKey) { result in
            switch result {
                case let .success(index):
                    self.lists = index
                    self.normaliseData()
                    
                case let .failure(error):
                    modelChannel.log("Loading lists failed: \(error)")
                    self.loaded = true
            }
        }
    }
    
    func normaliseData() {
        modelChannel.log("Normalising data")
        let allBooks = Set(books.index.keys)
        let allLists = lists.index.values
        for list in allLists {
            let entries = Set(list.entries)
            let normalised = entries.intersection(allBooks)
            if normalised.count < entries.count {
                var updated = list
                updated.entries = Array(normalised)
                lists.index[list.id] = updated
                modelChannel.log("Removed some missing entries for \(list.name)")
            }
        }
        
        loaded = true
        modelChannel.log("Loading completed.")
    }
    
    var appName: String { "Bookish Lists" }
    
    func migrate(from store: ObjectStore) {
    }
    
    func save(to store: ObjectStore) {
//        if loaded {
//            lists.save(to: store, idKey: .listsKey) { result in
//                if !result {
//                    modelChannel.log("Saving lists failed")
//                } else {
//                    self.books.save(to: store, idKey: .booksKey) { result in
//                        modelChannel.log(result ? "Saving done" : "Saving books failed")
//                    }
//                }
//            }
//        }
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
