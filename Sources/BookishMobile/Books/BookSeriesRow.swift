// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel

class BookSeriesRow: BookDetailRow {
    @IBOutlet var seriesButton: UIButton!
    var series: Entry!

    override func setup(row: DetailDataSource.RowInfo, book: Book, source: DetailDataSource) {
        assert(row.category == .series)
        series = source.series(for: row)
        label.text = series.series?.name
        seriesButton.setTitle(series.series?.name, for: .normal)
    }
}
