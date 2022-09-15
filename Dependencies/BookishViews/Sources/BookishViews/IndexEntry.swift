// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/02/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import SwiftUIExtensions

enum ListEntryKind {
    case allBooks
    case list(CDRecord)
    case book(CDRecord, CDRecord?)
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
    
    init(book: CDRecord, in list: CDRecord? = nil) {
        self.kind = .book(book, list)
    }
    
    init(list: CDRecord) {
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

}