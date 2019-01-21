// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 30/11/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class BookPublisherCell: AnnotatedTableCellView {
    @IBOutlet weak var publisherField: NSTextField!
    @IBOutlet weak var publisherCombo: AnnotatedComboBox!
    
    var detailView: BookDetailViewController!
}

extension BookPublisherCell: BookDetailTableCell {
    func setup(for view: BookDetailViewController, row: DetailDataSource.RowInfo) {
        assert(row.category == .publisher)
        let source = view.source
        detailView = view
        publisherField?.isHidden = view.editing
        publisherCombo?.isHidden = !view.editing
        
        if row.placeholder {
            publisherField?.placeholderString = "publisher name"
        } else {
            let publisher = source.publisher(for: row)
            objectValue = publisher
            if let name = publisher.name {
                publisherField?.stringValue = name
                publisherCombo?.stringValue = name
            }
        }
    }
    
    func keyView() -> NSView? {
        return detailView.editing ? publisherCombo : nil
    }
}

extension BookPublisherCell: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[PublisherAction.publisherKey] = objectValue as? Publisher
    }
    
}

extension BookPublisherCell: NSComboBoxDelegate {
    func comboBoxSelectionDidChange(_ notification: Notification) {
        if let publishers = detailView?.publisherList?.arrangedObjects as? [Publisher] {
            let index = publisherCombo.indexOfSelectedItem
            if index != -1 {
                let newPublisher = publishers[publisherCombo.indexOfSelectedItem]
                changePublisher(to: newPublisher)
            }
        }
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        super.controlTextDidEndEditing(obj)
        if let context = detailView?.cvm.managedObjectContext {
            let newName = publisherCombo.stringValue
            if let newPublisher = Publisher.named(newName, in: context) {
                changePublisher(to: newPublisher)
            } else {
                changePublisher(creating: newName)
            }
        }
    }
    
    func changePublisher(to newPublisher: Publisher) {
        if let publisher = objectValue as? Publisher, newPublisher != publisher {
            let actionManager = application.actionManager
            let info = ActionInfo(sender: self)
            info[PublisherAction.publisherKey] = newPublisher
            actionManager.perform(identifier: "ChangePublisher", info: info)
        }
    }
    
    func changePublisher(creating newPublisherName: String) {
        let actionManager = application.actionManager
        let info = ActionInfo(sender: self)
        info[PublisherAction.newPublisherKey] = newPublisherName
        actionManager.perform(identifier: "ChangePublisher", info: info)
    }
    
}
