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
    var detailView: GenericDetailController!
}

extension BookSeriesCell: DetailTableCell {
    func setup(for row: DetailItem, of view: GenericDetailController) {
        assert(row is SeriesDetailItem)
        
        detailView = view
        if row.placeholder {
            seriesCombo.stringValue = ""
            positionField.stringValue = ""
        } else if let item = row as? SeriesDetailItem, let series = item.series, let selection = view.selectedItems as? [Book] {
            objectValue = series
            if let name = series.name {
                seriesField?.stringValue = name
                seriesCombo?.stringValue = name
            }
            
            
            switch selection.count {
            case 1:
                positionField.integerValue = selection[0].position(in: series)
                
            default:
                positionField.objectValue = ""
            }
        }
        
        seriesCombo.isHidden = !view.editing
        seriesField.isHidden = view.editing
        positionField.isEditable = view.editing
    }
    
    func keyView() -> NSView? {
        return detailView.editing ? seriesCombo : nil
    }
}

extension BookSeriesCell: ActionContextProvider {
    func provide(context: ActionContext) {
        if let series = objectValue as? Series {
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

        if let context = detailView?.cvm.managedObjectContext, let control = obj.object as? NSControl {
            if control == seriesCombo {
                let newName = seriesCombo.stringValue
                if let updatedSeries = Series.named(newName, in: context, createIfMissing: false) {
                    changeSeries(to: updatedSeries)
                } else {
                    changeSeries(creating: newName)
                }
            } else if control == positionField {
                changePosition(to: positionField.integerValue)
            }
        }
    }
    
    func changePosition(to position: Int) {
        if let existingSeries = objectValue as? Series {
            let actionManager = application.actionManager
            let info = ActionInfo(sender: self)
            info[SeriesAction.seriesKey] = existingSeries
            info[SeriesAction.positionKey] = position
            actionManager.perform(identifier: "ChangeSeries", info: info)
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
            
            
            if let value = positionField.objectValue as? NSValue, value !== NSMultipleValuesMarker {
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
        if let value = positionField.objectValue as? NSValue, value !== NSMultipleValuesMarker {
            info[SeriesAction.positionKey] = positionField.integerValue
        }
        actionManager.perform(identifier: "ChangeSeries", info: info)
    }
    
}
