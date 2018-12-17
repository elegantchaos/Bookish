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
        case publishers = 2
        case series = 3
        
        static let names = ["Book", "Person", "Publisher", "Series"]
        
        func singluarName() -> String {
            return Mode.names[rawValue]
        }
    }
    
    typealias  WindowController = CollectionWindowController
    
    @objc let document: CollectionDocument
    @objc let managedObjectContext: NSManagedObjectContext
    @objc var bookIndex: NSArrayController?
    
    @objc var selectedIndexes: NSMutableIndexSet?
    @objc var selectedPeople: NSMutableIndexSet?
    @objc var selectedPublishers: NSMutableIndexSet?
    @objc var selectedSeries: NSMutableIndexSet?

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
    
    func addRelationshipItem(kind: String, shortcut: String) -> NSMenuItem {
        let item = NSMenuItem(title: kind, action: ActionManagerMac.Responder.performActionSelector, keyEquivalent: shortcut)
        item.identifier = NSUserInterfaceItemIdentifier(rawValue: "menu.AddRelationship(\"role\": \"\(kind)\")")
        item.keyEquivalentModifierMask = [.command, .option]
        return item
    }
    
    var addRelationshipMenu: NSMenu {
        get {
            var shortcuts = ["4","3","2","1"]
            let menu = NSMenu()
            let request: NSFetchRequest<Role> = Role.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            if let results = try? managedObjectContext.fetch(request) {
                for role in results {
                    if let name = role.name {
                        let shortcut = shortcuts.popLast() ?? ""
                        menu.addItem(addRelationshipItem(kind: name, shortcut: shortcut))
                    }
                }
            }
            return menu
        }
    }    
}
