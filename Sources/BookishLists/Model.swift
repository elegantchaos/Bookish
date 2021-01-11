// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import KeyValueStore

extension String {
    static let listsKey = "Lists"
}

struct Book: Identifiable {
    let id: UUID
    let name: String
}

struct ListEntry {
    let list: UUID
    let properties: UUID
}

struct BookList: Identifiable, Codable {
    let id: UUID
    let name: String
    let entries: [UUID:UUID]
}

class Model: ObservableObject {
    @Published var lists: [BookList] = []

    init() {
        lists = []
    }
    
    init(from store: KeyValueStore) {
        let decoder = JSONDecoder()
        lists.load(from: store, with: decoder, idKey: .listsKey)
        migrate(from: store)
        
    }
    
    var appName: String { "Bookish Lists" }
    
    func migrate(from store: KeyValueStore) {
    }
    
    func save(to store: KeyValueStore) {
        let encoder = JSONEncoder()
        lists.save(to: store, with: encoder)
    }
    

}
