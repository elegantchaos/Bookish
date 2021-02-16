// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/02/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

enum ListEntryKind {
    case allBooks
    case list(CDList)
    case entry(CDEntry)
}

extension UUID {
    static let allBooksId = UUID(uuidString: "A6CC34C5-ECB4-4F33-B177-EBF1A1FCA91D")!
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
    
    init(book: CDEntry) {
        self.kind = .entry(book)
    }
    
    init(list: CDList) {
        self.kind = .list(list)
    }

    var id: UUID {
        switch self.kind {
            case .allBooks: return .allBooksId
            case .entry(let entry): return entry.id
            case .list(let list): return list.id
        }
    }

    var children: [ListEntry]? {
        switch kind {
            case .allBooks: return nil
            case .entry: return nil
            case .list(let list):
                let entries = list.sortedEntries
                let lists = list.sortedLists
                var children: [ListEntry] = []
                children.append(contentsOf: entries.map({ ListEntry(book: $0)}))
                children.append(contentsOf: lists.map({ ListEntry(list: $0)}))
                return children.count > 0 ? children : nil
        }
    }
}

