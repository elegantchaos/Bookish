// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 30/11/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class PublisherCell: AnnotatedTableCellView {
    @IBOutlet weak var publisherField: NSTextField!
    @IBOutlet weak var publisherCombo: AnnotatedComboBox!
    
    var detailView: DetailController!
}

extension PublisherCell: DetailTableCell {
    func setup(for row: DetailItem, of view: DetailController) {
        assert(row is PublisherDetailItem)

        detailView = view

        if row.placeholder {
            publisherCombo.stringValue = ""
            detailChannel.debug("setup as a placeholder")
        } else if let item = row as? PublisherDetailItem, let publisher = item.publisher {
            objectValue = publisher
            if let name = publisher.name {
                if view.editing {
                    if let index = view.index(of: publisher) {
                        detailChannel.debug("setup with selection \(index) \(name)")
                        publisherCombo.selectItem(at: index)
                    } else {
                        detailChannel.debug("setup with unknown name \(name)")
                        publisherCombo.stringValue = name
                    }
                } else {
                    publisherField.stringValue = name
                }
            }
        }
        
        publisherField?.isHidden = view.editing
        publisherCombo?.isHidden = !view.editing
    }
    
    func keyView() -> NSView? {
        return detailView.editing ? publisherCombo : nil
    }
}

extension PublisherCell: ActionContextProvider {
    func provide(context: ActionContext) {
        context[PublisherAction.publisherKey] = objectValue
        context.info.addObserver(self)
        if detailView.editing {
            let publisher = detailView.publisher(at: publisherCombo.indexOfSelectedItem)
            context[PublisherAction.newPublisherKey] = publisher ?? publisherCombo.stringValue
        }
    }
    
}

extension PublisherCell: BookChangeObserver {
    func added(publisher: Publisher) {
        objectValue = publisher
    }
    func removed(publisher: Publisher) {
        objectValue = nil
    }
}
