//
//  CDRecord+Sorting.swift
//  BookishLists
//
//  Created by Sam Deane on 23/11/2021.
//

import Foundation

extension Array where Element == CDRecord {
    var sortedByName: [Element] {
        return sorted { ($0.name == $1.name) ? ($0.id < $1.id) : ($0.name < $1.name) }
    }
}


extension Set where Element == CDRecord {
    var sortedByName: [Element] {
        return sorted { ($0.name == $1.name) ? ($0.id < $1.id) : ($0.name < $1.name) }
    }
}
