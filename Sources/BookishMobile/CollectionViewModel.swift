// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

@objc class CollectionViewModel: NSObject {
    enum Mode: Int {
        case books = 0
        case people = 1
        case publisher = 2
        case series = 3
        case settings = 4
    }
    
    @objc dynamic var modeIndex: Int = 0
    
    var mode: Mode {
        get { return Mode(rawValue: modeIndex)! }
        set (value) { modeIndex = value.rawValue }
    }

    let bookIndexSorting = [NSSortDescriptor(key: "sortName", ascending: true)]
    let personIndexSorting = [NSSortDescriptor(key: "sortName", ascending: true)]
    let relationshipSorting = [NSSortDescriptor(key: "role.name", ascending: true)]
    let entrySorting = [NSSortDescriptor(key: "index", ascending: true)]
    let publisherSorting = [NSSortDescriptor(key: "sortName", ascending: true)]
    let seriesSorting = [NSSortDescriptor(key: "sortName", ascending: true)]
}
