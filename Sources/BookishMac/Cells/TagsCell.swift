// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import AppKit
import Actions
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

        let tagList: [Tag] = view.cvm.managedObjectContext.everyEntity()
        for tag in tagList {
            if let name = tag.name {
                allTags[name] = tag
            }
        }
        
        initialTags.removeAll()
        if let info = row as? TagsDetailItem {
            initialTags = info.tags
        }
        
        detailView = view
        tagsField.objectValue = initialTags
        changed = false
    }
    
    func keyView() -> NSView? {
        return tagsField
    }
    
    override func prepareForReuse() {
        changed = false
        initialTags = []
        allTags = [:]
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
}

extension TagsCell {
    func controlTextDidChange(_ obj: Notification) {
        changed = true
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        if changed, let tags = tagsField.objectValue as? [Tag] {
            let currentTags = Set<Tag>(tags)
            let addedTags = currentTags.subtracting(initialTags)
            let removedTags = initialTags.subtracting(currentTags)
            print("added \(addedTags)")
            print("removed \(removedTags)")
            
            if let selection = detailView.index.selectedObjects as? [ModelObject] {
                for object in selection {
                    if var tags = object.value(forKey: "tags") as? Set<Tag> {
                        tags.subtract(removedTags)
                        tags.formUnion(addedTags)
                        object.setValue(tags, forKey: "tags")
                    }
                }
            }
        }
    }
}
