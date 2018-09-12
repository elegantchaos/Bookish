// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import CoreData
import Actions

@objc class CollectionDocumentViewModel: NSObject, DocumentViewModel {
    typealias  WindowController = CollectionWindowController
    
    @objc let document: CollectionDocument
    @objc let managedObjectContext: NSManagedObjectContext
    @objc var bookIndex: NSArrayController?
    @objc var selectedIndexes: NSMutableIndexSet?
    
    init(document: CollectionDocument) {
        self.document = document
        self.managedObjectContext = document.managedObjectContext!
    }
    
    func addPersonItem(kind: String, shortcut: String) -> NSMenuItem {
        let item = NSMenuItem(title: kind, action: ActionManager.performActionSelector, keyEquivalent: shortcut)
        item.identifier = NSUserInterfaceItemIdentifier(rawValue: "menu.AddPerson.\(kind.lowercased())")
        item.keyEquivalentModifierMask = [.command, .option]
        return item
    }
    
    var addPersonMenu: NSMenu {
        get {
            let menu = NSMenu()
            menu.addItem(addPersonItem(kind: "Author", shortcut: "A"))
            menu.addItem(addPersonItem(kind: "Editor", shortcut: "E"))
            menu.addItem(addPersonItem(kind: "Illustrator", shortcut: "I"))
            menu.title = "AddPersonPopup"
            menu.identifier = NSUserInterfaceItemIdentifier(rawValue: "AddPersonPopup")
            return menu
        }
    }
}
