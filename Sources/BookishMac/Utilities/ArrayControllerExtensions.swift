// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

extension NSArrayController {
    func selectionSummary(entity: String) -> String {
        let arranged = (arrangedObjects as! NSArray).count
        let selected = selectionIndexes.count
        let key = (arranged == 1) ? "\(entity).singular" : "\(entity).plural"
        let kind = NSLocalizedString(key, comment: "entity label")
        if selected < 2 {
            return "\(arranged) \(kind)"
        } else {
            return "\(selected) of \(arranged) \(kind)"
        }
    }
}
