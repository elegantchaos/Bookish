// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Cocoa
import BookishModel
import Actions
import ActionsKit
import Logger
import BookishCore
import CloudKit

let applicationChannel = Logger("Application")

@NSApplicationMain class Application: NSObject {
    
    let windowControllerFactory = WindowControllerFactory<CollectionViewModel>()
    let actionManager = ActionManagerMac()
    let importManager = ImportManager()
    let imageCache = NSImageCache()
    let cloudManager = CloudManager()
    let uiTesting = CommandLine.arguments.contains("--ui-testing")
    var testDocument = CommandLine.arguments.contains("--test-document")
    let noBlankDocument = CommandLine.arguments.contains("--no-blank-document")
    var viewModel: CollectionViewModel!
    var watchedMenuItem: NSMenuItem?
    var windowController: CollectionWindowController!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if uiTesting {
            resetState()
        }
    }

    static var sharedInstance: Application {
        return NSApp.delegate as! Application
    }
    
    func resetState() {
        let defaultsName = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: defaultsName)
    }
    
    fileprivate func setupActions() {
        actionManager.register(ModelAction.standardActions())
        actionManager.register(RelationshipUIAction.standardActions())
        actionManager.register(ImporterAction.standardActions())
        actionManager.register(ItemAction.standardActions())
        actionManager.register([
            ScanSeriesAction(identifier: "ScanSeries"),
            ShowDatePickerAction(identifier: "ShowDatePicker"),
            ToggleEditingAction(identifier: "ToggleEditing")
            ])
        
        actionManager.installResponder()
    }
    
    fileprivate func setupTransformers() {
        ValueTransformer.setValueTransformer(AuthorsTransformer(), forName: AuthorsTransformer.name)
        ValueTransformer.setValueTransformer(AuthorSelectionTransformer(), forName: AuthorSelectionTransformer.name)
        ValueTransformer.setValueTransformer(DateTransformer(), forName: DateTransformer.name)
    }

    fileprivate func setupWindow(for collection: SyncedCollection) {
        let viewModel = CollectionViewModel(collection: collection)
        self.viewModel = viewModel
        let windowController = self.windowControllerFactory.instantiateController(for: viewModel)
        self.windowController = windowController
        windowController.showWindow(self)
    }

    fileprivate func setupCloudKit() {
        cloudManager.setup(name: "mac")
    }
}

extension Application: NSApplicationDelegate {
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        setupActions()
        setupTransformers()
        
        let mode: CollectionContainer.PopulateMode = testDocument ? .replaceWithTestData : .defaultRoles
        let _ = SyncedCollection(identifier: cloudManager.collectionIdentifier, mode: mode) { (sc, error) in
            if let error = error {
                fatalError("failed to load \(error)")
            }
            
            let collection = sc as! SyncedCollection
            self.setupCloudKit()
            self.setupWindow(for: collection)
            collection.sync()
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        applicationChannel.log("finished launching")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        applicationChannel.debug("will terminate")
    }
    
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return !noBlankDocument
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        viewModel.collection.save()
        viewModel.collection.sync()
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        viewModel.collection.save()
        viewModel.collection.sync()
    }
}

extension Application: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(delete(_:)):
            // special case for the Delete menu item in the Edit menu
            // we want to leave the action as the default, so that it works in controls in the normal
            // way, but when it falls down lower we want to map it to the DeleteItem action
            let validation = Application.sharedInstance.actionManager.validate(identifier: "DeleteItem", info: ActionInfo(sender: menuItem))
            menuItem.title = validation.name ?? "Delete"
            
            watchForDeleteItemClosing(item: menuItem)
            return validation.enabled

        default:
            return true
        }
    }
    
    @IBAction func undo(_ sender: Any) {
        viewModel.managedObjectContext.undoManager?.undo()
    }
    
    @IBAction func redo(_ sender: Any) {
        viewModel.managedObjectContext.undoManager?.redo()
    }
    
    @IBAction func delete(_ sender: Any) {
        Application.sharedInstance.actionManager.perform(identifier: "DeleteItem", info: ActionInfo(sender: sender))
    }
}

extension Application: NSMenuDelegate {
    func watchForDeleteItemClosing(item: NSMenuItem) {
        // since we let the action change the name of the menu item, we need a way to ensure that it
        // gets reset once the menu has been hidden; we do this by becoming the delegate of the edit
        // menu and implementing menuDidClose
        watchedMenuItem = item
        assert((item.menu?.delegate == nil) || (item.menu?.delegate === self))
        item.menu?.delegate = self
    }
    
    func menuDidClose(_ menu: NSMenu) {
        if menu == watchedMenuItem?.menu {
            watchedMenuItem?.title = "Delete"
            menu.delegate = nil
        }
    }
}
