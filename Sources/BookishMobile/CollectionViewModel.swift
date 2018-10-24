// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

class CollectionViewModel {
    let bookIndexSorting = [NSSortDescriptor(key: "name", ascending: true)]
    let personIndexSorting = [NSSortDescriptor(key: "name", ascending: true)]
    let personRoleSorting = [NSSortDescriptor(key: "role.name", ascending: true)]
}
