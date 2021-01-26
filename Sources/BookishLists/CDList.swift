//
//  CDList.swift
//  BookishLists
//
//  Created by Sam Developer on 26/01/2021.
//

import CoreData

class CDList: NSManagedObject {
    var sortedBooks: [CDBook] {
        guard let books = books as? Set<CDBook> else { return [] }
        let sorted = books.sorted { ($0.name ?? "") < ($1.name ?? "") }
        return sorted
    }
}
