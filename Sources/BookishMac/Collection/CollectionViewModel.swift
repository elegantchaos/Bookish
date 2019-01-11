// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import CoreData
import ActionsKit
import BookishModel

@objc class CollectionViewModel: NSObject, WindowControllerViewModel {
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
    
    let collection: SyncedCollection
    
    typealias WindowController = CollectionWindowController
    typealias Owner = CollectionViewController
    
    @objc let managedObjectContext: NSManagedObjectContext
    @objc var bookIndex: NSArrayController?
    
    @objc var selectedBooks: NSMutableIndexSet?
    @objc var selectedPeople: NSMutableIndexSet?
    @objc var selectedPublishers: NSMutableIndexSet?
    @objc var selectedSeries: NSMutableIndexSet?

    @objc dynamic var modeIndex: Int = 0
    
    // bindable fonts
    @objc let detailFont = NSFont.systemFont(ofSize: 14, weight: NSFont.Weight.regular)
    @objc let labelFont = NSFont.systemFont(ofSize: 14, weight: NSFont.Weight.regular)
    @objc let titleFont = NSFont.systemFont(ofSize: 18, weight: NSFont.Weight.regular)
    @objc let indexFont = NSFont.systemFont(ofSize: 14, weight: NSFont.Weight.regular)

    // bindable sort descriptors
    @objc var bookSorting = [NSSortDescriptor(key: "sortName", ascending: true)]
    @objc var personSorting = [NSSortDescriptor(key: "sortName", ascending: true)]
    @objc var publisherSorting = [NSSortDescriptor(key: "sortName", ascending: true)]
    @objc var seriesSorting = [NSSortDescriptor(key: "sortName", ascending: true)]
    @objc var roleSorting = [NSSortDescriptor(key: "name", ascending: true)]

    var mode: Mode {
        get { return Mode(rawValue: modeIndex)! }
        set (value) { modeIndex = value.rawValue }
    }
    
    init(collection: SyncedCollection) {
        self.collection = collection
        self.managedObjectContext = collection.managedObjectContext
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
            request.sortDescriptors = roleSorting
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
