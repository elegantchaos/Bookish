// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel
import Actions

class BookSeriesCell: AnnotatedTableCellView {
    @IBOutlet weak var seriesField: NSTextField!
    @IBOutlet weak var seriesCombo: AnnotatedComboBox!
    @IBOutlet weak var positionField: NSTextField!
    var detailView: BookDetailViewController?
}

extension BookSeriesCell: BookDetailTableCell {
    func setup(for view: BookDetailViewController, row: DetailDataSource.RowInfo) {
        assert(row.category == .series)
        let source = view.source
        detailView = view
        if row.placeholder {
            
        } else {
            let series = source.series(for: row)
            objectValue = series
            if let name = series.name {
                seriesField?.stringValue = name
                seriesCombo?.stringValue = name
            }
            
            let selection = view.selectedItems()
            switch selection.count {
            case 0:
                positionField.stringValue = ""
                
            case 1:
                positionField.integerValue = selection[0].position(in: series)
                
            default:
                positionField.objectValue = NSMultipleValuesMarker
            }
        }
        
        seriesCombo.isHidden = !view.editing
        seriesField.isHidden = view.editing
    }
    
    func keyView() -> NSView? {
        return seriesField
    }
}

extension BookSeriesCell: ActionContextProvider {
    func provide(context: ActionContext) {
        if let entry = objectValue as? SeriesEntry, let series = entry.series {
            context.info[SeriesAction.seriesKey] = series
        }
    }
}


extension BookSeriesCell: NSComboBoxDelegate {
    func comboBoxSelectionDidChange(_ notification: Notification) {
        if let allSeries = detailView?.seriesList?.arrangedObjects as? [Series] {
            let index = seriesCombo.indexOfSelectedItem
            if index != -1 {
                let updatedSeries = allSeries[seriesCombo.indexOfSelectedItem]
                changeSeries(to: updatedSeries)
            }
        }
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        super.controlTextDidEndEditing(obj)
        if let context = detailView?.cvm.managedObjectContext {
            let newName = seriesCombo.stringValue
            if let updatedSeries = Series.named(newName, in: context) {
                changeSeries(to: updatedSeries)
            } else {
                changeSeries(creating: newName)
            }
        }
    }
    
    func changeSeries(to updatedSeries: Series) {
        let existingSeries = objectValue as? Series
        if updatedSeries != existingSeries {
            let actionManager = application.actionManager
            let info = ActionInfo(sender: self)
            info[SeriesAction.newSeriesKey] = updatedSeries
            if let existingSeries = existingSeries {
                info[SeriesAction.seriesKey] = existingSeries
            }
            if (positionField.objectValue as? NSValue) != NSMultipleValuesMarker {
                info[SeriesAction.positionKey] = positionField.integerValue
            }
            actionManager.perform(identifier: "ChangeSeries", info: info)
        }
    }
    
    func changeSeries(creating newSeriesName: String) {
        let actionManager = application.actionManager
        let info = ActionInfo(sender: self)
        info[SeriesAction.newSeriesKey] = newSeriesName
        if let existingSeries = objectValue as? Series {
            info[SeriesAction.seriesKey] = existingSeries
        }
        if (positionField.objectValue as? NSValue) != NSMultipleValuesMarker {
            info[SeriesAction.positionKey] = positionField.integerValue
        }
        actionManager.perform(identifier: "ChangeSeries", info: info)
    }
    
}
