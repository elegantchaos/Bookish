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

    override func setupContent(row: DetailItem, book: Book) {
        assert(row is SeriesDetailItem)
        if row.placeholder {
            
        } else {
            series = source.series(for: row)
            if let name = series?.name {
                seriesButton.setTitle(name, font: application.viewModel.detailFont)
            }
        }
    }
}

extension BookSeriesRow: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[SeriesAction.seriesKey] = series
    }
}

