// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import BookishModel
import UIKit

class SeriesRow: BookDetailRow {
    @IBOutlet var seriesButton: LinkButton!
    var series: Series!

    override func setupContent(row: DetailItem, book: Book) {
        if let item = row as? SeriesDetailItem {
            if item.placeholder {
                
            } else {
                series = item.series
                if let name = item.series?.name {
                    seriesButton.setTitle(name, font: application.viewState.detailFont)
                    seriesButton.linkedObject = series
                }
            }
        }
    }
}

extension SeriesRow: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[SeriesAction.seriesKey] = series
    }
}

