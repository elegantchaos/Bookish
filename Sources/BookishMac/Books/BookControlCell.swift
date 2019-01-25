// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/01/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import BookishModel
import AppKit

class BookControlCell: NSTableCellView, BookDetailTableCell {
    
    @IBOutlet weak var removeButton: NSButton!
    private var objectKey: String = ""
    
    func setup(for detailView: BookDetailViewController, row: DetailDataSource.RowInfo) {
        let source = detailView.source

        var hidden = false
        var identifier: String? = nil
        
        switch row.kind {
        case .series:
            if !row.placeholder {
                objectValue = source.series(for: row)
                objectKey = SeriesAction.seriesKey
                identifier = "button.RemoveSeries"
            }

        case .person:
            if !row.placeholder {
                objectValue = source.relationship(for: row)
                objectKey = PersonAction.relationshipKey
                identifier = "button.RemoveRelationship"
            }
            
        case .publisher:
            if !row.placeholder {
                objectValue = source.publisher(for: row)
                objectKey = PublisherAction.newPublisherKey
                identifier = "button.RemovePublisher"
            }
            
        default:
            hidden = true
        }
        
        removeButton.isHidden = hidden
        if let identifier = identifier {
            removeButton.identifier = NSUserInterfaceItemIdentifier(rawValue: identifier)
        }
    }
    
    func keyView() -> NSView? {
        return nil
    }
}

extension BookControlCell: ActionContextProvider {
    func provide(context: ActionContext) {
        if let item = objectValue as? ModelObject, !objectKey.isEmpty {
            context[objectKey] = item
        }
    }
}
