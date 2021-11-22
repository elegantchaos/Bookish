// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/02/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import SwiftUIExtensions

enum ListEntryKind {
    case allBooks
    case list(CDList)
    case book(CDBook, CDList?)
}

extension String {
    static let allBooksID = "all-books"
}

struct ListEntry: Identifiable, Hashable {
    static func == (lhs: ListEntry, rhs: ListEntry) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
    
    
    let kind: ListEntryKind
    
    init() {
        self.kind = .allBooks
    }
    
    init(book: CDBook, in list: CDList? = nil) {
        self.kind = .book(book, list)
    }
    
    init(list: CDList) {
        self.kind = .list(list)
    }

    var id: String {
        switch self.kind {
            case .allBooks:
                return .allBooksID

            case .list(let list):
                return list.id
                
            case .book(let book,let list):
                if let list = list {
                    return "\(list.id)-\(book.id)"
                } else {
                    return book.id
                }
        }
    }

    var children: [ListEntry]? {
        switch kind {
            case .allBooks: return nil
            case .book: return nil
            case .list(let list):
                let entries = list.sortedBooks
                let lists = list.sortedLists
                var children: [ListEntry] = []
                children.append(contentsOf: entries.map({ ListEntry(book: $0, in: list)}))
                children.append(contentsOf: lists.map({ ListEntry(list: $0)}))
                return children.count > 0 ? children : nil
        }
    }
}
