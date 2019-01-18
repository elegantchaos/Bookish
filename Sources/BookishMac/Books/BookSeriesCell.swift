// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel
import Actions

class BookSeriesCell: NSTableCellView {
    @IBOutlet weak var seriesField: NSTextField!
    @IBOutlet weak var indexField: NSTextField!
    var detailView: BookDetailViewController?
}

extension BookSeriesCell: BookDetailTableCell {
    func setup(for view: BookDetailViewController, row: DetailDataSource.RowInfo) {
        assert(row.category == .series)
        let source = view.source
        detailView = view
        if row.placeholder {
            
        } else {
            let entry = source.series(for: row)
            objectValue = entry
            if let name = entry.series?.name {
                seriesField?.stringValue = name
            }
            indexField.integerValue = Int(entry.index)
        }
        
    }
    
    func keyView() -> NSView? {
        return seriesField
    }
}

extension BookSeriesCell: ActionContextProvider {
    func provide(context: ActionContext) {
        if let entry = objectValue as? Entry, let series = entry.series {
            context.info[SeriesAction.seriesKey] = series
        }
    }
}
