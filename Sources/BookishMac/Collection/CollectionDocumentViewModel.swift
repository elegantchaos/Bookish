// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import CoreData
import ActionsKit
import BookishModel

@objc class CollectionDocumentViewModel: NSObject, DocumentViewModel {
    enum Mode: Int {
        case books = 0
        case people = 1
    }
    
    typealias  WindowController = CollectionWindowController
    
    @objc let document: CollectionDocument
    @objc let managedObjectContext: NSManagedObjectContext
    @objc var bookIndex: NSArrayController?
    @objc var selectedIndexes: NSMutableIndexSet?
    @objc var selectedPeople: NSMutableIndexSet?
    
    @objc dynamic var modeIndex: Int = 0
    
    @objc let detailFont = NSFont.systemFont(ofSize: 14, weight: NSFont.Weight.regular)
    @objc let labelFont = NSFont.systemFont(ofSize: 14, weight: NSFont.Weight.regular)
    @objc let titleFont = NSFont.systemFont(ofSize: 18, weight: NSFont.Weight.regular)
    @objc let indexFont = NSFont.systemFont(ofSize: 14, weight: NSFont.Weight.regular)

    var mode: Mode {
        get { return Mode(rawValue: modeIndex)! }
        set (value) { modeIndex = value.rawValue }
    }
    
    init(document: CollectionDocument) {
        self.document = document
        self.managedObjectContext = document.managedObjectContext!
    }
    
    func addPersonItem(kind: String, shortcut: String) -> NSMenuItem {
        let item = NSMenuItem(title: kind, action: ActionManagerMac.Responder.performActionSelector, keyEquivalent: shortcut)
        item.identifier = NSUserInterfaceItemIdentifier(rawValue: "menu.AddPerson.\(kind)")
        item.keyEquivalentModifierMask = [.command, .option]
        return item
    }
    
    var addPersonMenu: NSMenu {
        get {
            var shortcuts = ["4","3","2","1"]
            let menu = NSMenu()
            let request: NSFetchRequest<Role> = Role.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            if let results = try? managedObjectContext.fetch(request) {
                for role in results {
                    if let name = role.name {
                        let shortcut = shortcuts.popLast() ?? ""
                        menu.addItem(addPersonItem(kind: name, shortcut: shortcut))
                    }
                }
            }
            return menu
        }
    }
    
    var importMenu: NSMenu {
        get {
            let menu = NSMenu()
            let importManager = Application.sharedInstance.importManager
            for importer in importManager.sortedImporters {
                let item = NSMenuItem(title: importer.name, action: ActionManagerMac.Responder.performActionSelector, keyEquivalent: "")
                item.identifier = NSUserInterfaceItemIdentifier(rawValue: "menu.Import.\(importer.name)")
                menu.addItem(item)
            }
            return menu
        }
    }

}
