// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel

@objc class CollectionViewState: NSObject {
    let bookSorting = [NSSortDescriptor(key: "sortName", ascending: true)]
    let personIndexSorting = [NSSortDescriptor(key: "sortName", ascending: true)]
    let relationshipSorting = [NSSortDescriptor(key: "role.name", ascending: true)]
    let entrySorting = [NSSortDescriptor(key: "position", ascending: true)]
    let publisherSorting = [NSSortDescriptor(key: "sortName", ascending: true)]
    let seriesSorting = [NSSortDescriptor(key: "sortName", ascending: true)]
    let roleSorting = [NSSortDescriptor(key: "name", ascending: true)]

    let detailFont: UIFont
    let labelFont: UIFont
    let titleFont: UIFont
    let indexFont: UIFont

    var showDebug: Bool
    
    override init() {
        let defaults = UserDefaults.standard
        
        detailFont = UIFont.preferredFont(forTextStyle: .body)
        labelFont = detailFont
        titleFont = UIFont.preferredFont(forTextStyle: .title1)
        indexFont = UIFont.preferredFont(forTextStyle: .title3)
        showDebug = defaults.bool(forKey: "showDebug")
        
        super.init()
    }
    
    func save() {
        let defaults = UserDefaults.standard
        defaults.set(showDebug, forKey: "showDebug")
    }
    
}

extension CollectionViewState: DetailContext {
    
}
