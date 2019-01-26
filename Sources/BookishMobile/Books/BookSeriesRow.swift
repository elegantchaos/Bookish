// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import BookishModel
import UIKit

class BookSeriesRow: BookDetailRow {
    @IBOutlet var seriesButton: UIButton!
    var series: Series!

    override func setup(row: DetailDataSource.RowInfo, book: Book, source: DetailDataSource) {
        assert(row.category == .series)
        series = source.series(for: row)
        if let name = series?.name {
            label.text = name
            seriesButton.setTitle(name, for: .normal)
        }
    }
}

extension BookSeriesRow: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[SeriesAction.seriesKey] = series
    }
}

