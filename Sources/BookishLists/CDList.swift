// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import SwiftUI
import SwiftUIExtensions

class CDList: NSManagedObject {
    var sortedBooks: [CDBook] {
        guard let books = books as? Set<CDBook> else { return [] }
        let sorted = books.sorted { ($0.name ?? "") < ($1.name ?? "") }
        return sorted
    }
    
    var children: [NSManagedObject]? {
        guard let books = books as? Set<CDBook> else { return nil }
        return Array(books)
    }
}

extension CDList: AutoLinked {
    var linkView: some View {
        BookListView(list: self)
    }
    var labelView: some View {
        Label(name ?? "Untitled", systemImage: "books.vertical")
    }
}
