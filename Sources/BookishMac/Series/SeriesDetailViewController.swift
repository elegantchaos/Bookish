// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


import AppKit
import BookishModel

class SeriesDetailViewController: DetailViewController<SeriesIndexViewController, Series> {
    static let entryViewID = NSUserInterfaceItemIdentifier(rawValue: "entry")
    
    override func rowsForSelection() -> [NSManagedObject] {
        let selected: [Series] = selectedItems()
        if selected.count == 1, let entries = selected[0].entries as? Set<Entry> {
            return entries.sorted(by: { $0.index < $1.index })
        }
        
        return []
    }
    
    override func identifier(for item: NSManagedObject) -> NSUserInterfaceItemIdentifier {
        switch item {
        case is Entry:
            return SeriesDetailViewController.entryViewID
        default:
            return super.identifier(for: item)
        }
    }
}
