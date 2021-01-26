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
    let stack: CoreDataStack
    var loaded = false

    init(stack: CoreDataStack) {
        self.stack = stack
    }
    
    var appName: String { "Bookish Lists" }
    
    func save() {
        let context = stack.viewContext
        guard context.hasChanges else { return }
        do {
            objectWillChange.send()
            try context.save()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
}
