// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import AppKit
import Actions
import ActionsKit
import BookishModel


class TagsCell: AnnotatedTableCellView {
    
    @IBOutlet weak var tagsField: NSTokenField!
    var detailView: DetailController!
    var allTags: [String:Tag] = [:]
    var initialTags: Set<Tag> = []
    var changed = false
}

extension TagsCell: DetailTableCell {
    func setup(for row: DetailItem, of view: DetailController) {
        assert(row is TagsDetailItem)
        if let info = row as? TagsDetailItem {
            initialTags = info.tags
        }
        
        detailView = view
        tagsField.isEditable = view.isEditing
        loadInitialContent()
    }
    
    func loadInitialContent() {
        let tagList: [Tag] = detailView.cvm.managedObjectContext.everyEntity()
        for tag in tagList {
            if let name = tag.name {
                allTags[name] = tag
            }
        }
        
        tagsField.objectValue = Array(initialTags)
        changed = false
    }
    
    func processChanges() {
        if  let tags = tagsField.objectValue as? [Tag] {
            let currentTags = Set<Tag>(tags)
            let addedTags = currentTags.subtracting(initialTags)
            let removedTags = initialTags.subtracting(currentTags)
            let info = ActionInfo(sender: self)
            info[ChangeTagsAction.addedTagsKey] = addedTags
            info[ChangeTagsAction.removedTagsKey] = removedTags
            application.actionManager.perform(identifier: "ChangeTags", info: info)
        }
    }
    
    func keyView() -> NSView? {
        return tagsField
    }
    
    override func prepareForReuse() {
        changed = false
        initialTags.removeAll()
        allTags.removeAll()
        tagsField.objectValue = nil
        detailView = nil
    }
    
    @IBAction func confirmDeletion(_ sender: NSMenuItem) {
        processChanges()
        if let window = window, let tag = sender.representedObject as? Tag, let name = tag.name {
            let actionManager = application.actionManager
            let alert = NSAlert()
            alert.messageText = "Tag.delete.message".localized(with: ["tag": name])
            alert.informativeText = "Tag.delete.info".localized(with: ["tag": name])
            alert.addButton(withTitle: "Tag.delete.ok".localized)
            alert.addButton(withTitle: "Tag.delete.cancel".localized)
            alert.showsSuppressionButton = true
            alert.beginSheetModal(for: window) { (response) in
                let info = ActionInfo(sender: sender)
                info[TagAction.tagKey] = tag
                actionManager.perform(identifier: "DeleteTag", info: info)
            }
        }
    }
    
    @IBAction func confirmRename(_ sender: NSMenuItem) {
        processChanges()
        if let window = window, let tag = sender.representedObject as? Tag, let name = tag.name {
            let actionManager = application.actionManager
            let alert = NSAlert()
            alert.messageText = "Tag.rename.message".localized(with: ["tag": name])
            alert.informativeText = "Tag.rename.info".localized(with: ["tag": name])
            alert.addButton(withTitle: "Tag.rename.ok".localized)
            alert.addButton(withTitle: "Tag.rename.cancel".localized)
            let field = NSTextField(string: name)
            alert.accessoryView = field
            
            alert.beginSheetModal(for: window) { (response) in
                let info = ActionInfo(sender: sender)
                info[TagAction.tagKey] = tag
                info[TagAction.tagNameKey] = field.stringValue
                actionManager.perform(identifier: "RenameTag", info: info)
            }
        }
    }
}

extension TagsCell: NSTokenFieldDelegate {
    func tokenField(_ tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [Any]? {
        return allTags.keys.filter({ return $0.starts(with: substring)})
    }
    
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        print("shouldAdd \(tokens) at \(index)")
        return tokens
    }
    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        guard let tag = representedObject as? Tag else {
            return nil
        }
        
        return tag.name ?? "<unknown-tag>"
    }
    
    func tokenField(_ tokenField: NSTokenField, editingStringForRepresentedObject representedObject: Any) -> String? {
        guard let tag = representedObject as? Tag else {
            return nil
        }
        
        return tag.name ?? "<unknown-tag>"
    }
    
    func tokenField(_ tokenField: NSTokenField, representedObjectForEditing editingString: String) -> Any? {
        if let tag = allTags[editingString] {
            return tag
        }
        
        let newTag = Tag.named(editingString, in: detailView.cvm.managedObjectContext)
        allTags[editingString] = newTag
        return newTag
    }
    
    func tokenField(_ tokenField: NSTokenField, hasMenuForRepresentedObject representedObject: Any) -> Bool {
        return detailView.isEditing
    }
    
    func tokenField(_ tokenField: NSTokenField, menuForRepresentedObject representedObject: Any) -> NSMenu? {
        guard let tag = representedObject as? Tag else {
            return nil
        }
        
        let menu = NSMenu(title: "Tag.menu.title".localized)
        let deleteItem = menu.addItem(withTitle: "Tag.delete.menu".localized, action: #selector(confirmDeletion(_:)), keyEquivalent: "")
        deleteItem.identifier = NSUserInterfaceItemIdentifier(rawValue: "DeleteTag")
        deleteItem.representedObject = tag
        
        let renameItem = menu.addItem(withTitle: "Tag.rename.menu".localized, action: #selector(confirmRename(_:)), keyEquivalent: "")
        renameItem.identifier = NSUserInterfaceItemIdentifier(rawValue: "RenameTag")
        renameItem.representedObject = tag
        
        return menu
    }
}

extension TagsCell {
    func controlTextDidChange(_ obj: Notification) {
        changed = true
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        if changed {
            processChanges()
        }
    }
}

extension TagsCell: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info.addObserver(self)
    }
}

extension TagsCell: TagObserver {
    func deleted(tags: Set<Tag>) {
        initialTags.subtract(tags)
        loadInitialContent()
    }
    
    func renamed(tags: Set<Tag>) {
        loadInitialContent()
    }
    
    func changed(adding addedTags: Set<Tag>, removing removedTags: Set<Tag>) {
        changed = false
        initialTags.subtract(removedTags)
        initialTags.formUnion(addedTags)
    }
}
