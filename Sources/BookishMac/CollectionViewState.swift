// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import CoreData
import ActionsKit
import BookishModel

@objc class CollectionViewState: NSObject {

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
    
    static let ViewStateChangedNotification = NSNotification.Name(rawValue: "ViewStateChanged")
    
    let collection: SyncedCollection
    
    @objc let managedObjectContext: NSManagedObjectContext

    @objc dynamic var modeIndex: Int = 0
    
    // bindable fonts
    @objc let detailFont = NSFont.systemFont(ofSize: 14, weight: NSFont.Weight.regular)
    @objc let labelFont = NSFont.systemFont(ofSize: 14, weight: NSFont.Weight.regular)
    @objc let titleFont = NSFont.systemFont(ofSize: 18, weight: NSFont.Weight.regular)
    @objc let indexFont = NSFont.systemFont(ofSize: 14, weight: NSFont.Weight.regular)

    var observers = [NSObjectProtocol]()
    var showDebug: Bool = false
    var entitySorting: [String:[NSSortDescriptor]]
    var mode: Mode {
        get {
            return Mode(rawValue: modeIndex)!
            
        }
        set (value) {
            modeIndex = value.rawValue
            
        }
    }
    
    init(collection: SyncedCollection) {
        self.collection = collection
        managedObjectContext = collection.managedObjectContext
        entitySorting = BookishModel.defaultSorting
        super.init()
        _ = loadFromDefaults()
        
        let centre = NotificationCenter.default
        observers.append(centre.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil) { (notification) in
            if self.loadFromDefaults() {
                centre.post(name: CollectionViewState.ViewStateChangedNotification, object: self)
            }
        })

    }
    
    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func loadFromDefaults() -> Bool {
        var changed = false
        
        let showDebug = UserDefaults.standard.bool(forKey: "showDebug")
        if showDebug != self.showDebug {
            self.showDebug = showDebug
            changed = true
        }
        
        return changed
    }
    
    func saveToDefaults() {
        
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
            request.sortDescriptors = entitySorting["Role"]
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

extension CollectionViewState: WindowControllerViewModel {
    typealias ViewController = CollectionViewController
    typealias WindowController = CollectionWindowController
    
    func didConnect(to window: CollectionWindowController) {
    }
}

extension CollectionViewState: DetailContext {
}
