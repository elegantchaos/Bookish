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
    
    func insertPersonItem(kind: String, shortcut: String) -> NSMenuItem {
        let item = NSMenuItem(title: kind, action: ActionManager.performActionSelector(), keyEquivalent: shortcut)
        item.identifier = NSUserInterfaceItemIdentifier(rawValue: "menu.InsertPerson.\(kind.lowercased())")
        item.keyEquivalentModifierMask = [.command, .option]
        return item
    }
    
    var addPersonMenu: NSMenu {
        get {
            let menu = NSMenu()
            menu.addItem(insertPersonItem(kind: "Author", shortcut: "A"))
            menu.addItem(insertPersonItem(kind: "Editor", shortcut: "E"))
            menu.addItem(insertPersonItem(kind: "Illustrator", shortcut: "I"))
            return menu
        }
    }
}
