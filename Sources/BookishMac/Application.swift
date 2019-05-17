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
import Sparkle

let applicationChannel = Logger("Application")
let updaterChannel = Logger("Updater")

@objc class PerformActionDummy: NSObject {
    @IBAction func performAction(_ sender: Any) {
    }
}

@NSApplicationMain class Application: NSObject, SPUStandardUserDriverDelegate {
    
    lazy var updateManager = makeUpdateManager()
    let windowControllerFactory = WindowControllerFactory<CollectionViewState>()
    let actionManager = ActionManagerMac()
    let importManager = ImportManager()
    let imageCache = NSImageCache()
    let cloudManager = CloudManager()
    let lookupManager = LookupManager()
    let uiTesting = CommandLine.arguments.contains("--ui-testing")
    var mode: SyncedCollection.PopulateMode = .populateWith(sample: "Roles")
    let noBlankDocument = CommandLine.arguments.contains("--no-blank-document")
    var viewModel: CollectionViewState?
    var watchedMenuItem: NSMenuItem?
    var windowController: CollectionWindowController!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if uiTesting {
            resetState()
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    static var sharedInstance: Application {
        return NSApp.delegate as! Application
    }

    
    func resetState() {
        let defaultsName = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: defaultsName)
    }
 
    fileprivate func setupLookups() {
        lookupManager.register(service: GoogleLookupService(name: "Google Books"))
        lookupManager.register(service: ExistingCollectionLookupService(name: "Existing Collection"))
    }
    
    fileprivate func setupActions() {
        actionManager.register(ModelAction.standardActions())
        actionManager.register(RelationshipUIAction.standardActions())
        actionManager.register(ImporterAction.standardActions())
        actionManager.register(ItemAction.standardActions())
        actionManager.register(EditingAction.standardActions())
        actionManager.register(LookupAction.standardActions())
        actionManager.register(FilterActions.standardActions())
        actionManager.register([
            ShowDatePickerAction(identifier: "ShowDatePicker"),
            ToggleScannerAction(identifier: "ToggleScanner"),
            NavigateBackAction(identifier: "NavigateBack"),
            NavigateForwardAction(identifier: "NavigateForward")
            ])
        
        actionManager.registerNotification() { (stage, action) in
            if stage == .willPerform {
                self.journal(action: action)
            }
        }

        actionManager.installResponder()
    }
    
    fileprivate func setupTransformers() {
        ValueTransformer.setValueTransformer(AuthorsTransformer(), forName: AuthorsTransformer.name)
        ValueTransformer.setValueTransformer(AuthorSelectionTransformer(), forName: AuthorSelectionTransformer.name)
        
        ValueTransformer.setValueTransformer(DateTransformer(timeStyle: .none), forName: NSValueTransformerName(rawValue: "DateToString"))
        ValueTransformer.setValueTransformer(DateTransformer(timeStyle: .short), forName: NSValueTransformerName(rawValue: "TimeToString"))
    }
    
    fileprivate func setupWindow(for collection: SyncedCollection) {
        let viewModel = CollectionViewState(collection: collection)
        self.viewModel = viewModel
        let windowController = self.windowControllerFactory.instantiateController(for: viewModel)
        self.windowController = windowController
        windowController.pushInitialObject()
    }
    
    fileprivate func setupCloudKit() {
        cloudManager.setup(name: "mac")
    }
    
    fileprivate func journal(action: ActionContext) {
        cloudManager.addJournalEntry(action.serializedDictionary)
    }
    
    @IBAction func showJournal(_ sender: Any) {
        print(cloudManager.allJournalEntries())
    }
    
    @IBAction func revealContainer(_ sender: Any) {
        if let url = viewModel?.collection.persistentStoreCoordinator.persistentStores.first?.url {
            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
        }
    }
}

extension Application: NSApplicationDelegate {
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        BookishModel.registerLocalizations()
        setupActions()
        setupLookups()
        setupTransformers()
        setupUpdates()
        
        var name: String? = nil
        var shouldSync = true
        let arguments = CommandLine.arguments
        if arguments.contains("--test-document") {
            mode = .replaceWith(sample: "Test")
            shouldSync = false
        } else if arguments.contains("--sample-document") {
            mode = .replaceWith(sample: "Sample")
            shouldSync = false
        } else if arguments.contains("--empty-document") {
            mode = .replaceWith(sample: "Roles")
            shouldSync = false
        }

        if arguments.contains("--debug-container") {
            name = "DebugContainer"
            shouldSync = false
        }
        
        let _ = SyncedCollection(name: name, identifier: cloudManager.collectionIdentifier, mode: mode, shouldSync: shouldSync) { (sc, error) in
            if let error = error {
                fatalError("failed to load \(error)")
            }
            
            let collection = sc as! SyncedCollection
            self.setupCloudKit()
            DispatchQueue.main.async {
                self.setupWindow(for: collection)
                collection.sync()
            }
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
        viewModel?.collection.save()
        viewModel?.collection.sync()
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        viewModel?.collection.save()
        viewModel?.collection.sync()
    }
}

extension Application: NSMenuItemValidation {
    /* override */ func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(delete(_:)):
            // special case for the Delete menu item in the Edit menu
            // we want to leave the action as the default, so that it works in controls in the normal
            // way, but when it falls down lower we want to map it to the DeleteItem action
            let validation = Application.sharedInstance.actionManager.validate(identifier: "DeleteItem", info: ActionInfo(sender: menuItem))
            menuItem.title = validation.name ?? "Delete"
            
            watchForDeleteItemClosing(item: menuItem)
            return validation.enabled
        
        case #selector(checkForUpdates(_:)):
            return updateManager.validate(menuItem)
            
        default:
            return true
        }
    }
    
    @IBAction func undo(_ sender: Any) {
        viewModel?.managedObjectContext.undoManager?.undo()
    }
    
    @IBAction func redo(_ sender: Any) {
        viewModel?.managedObjectContext.undoManager?.redo()
    }
    
    @IBAction func delete(_ sender: Any) {
        Application.sharedInstance.actionManager.perform(identifier: "DeleteItem", info: ActionInfo(sender: sender))
    }
    
    @IBAction func checkForUpdates(_ sender: Any) {
        updateManager.checkForUpdates(sender)
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

extension Application: SPUUpdaterDelegate {
    
    fileprivate func makeUpdateManager() -> SPUStandardUpdaterController {
        let updateManager = SPUStandardUpdaterController(updaterDelegate: self, userDriverDelegate: self)
        return updateManager
    }
    
    fileprivate func setupUpdates() {
        if let updater = updateManager.updater, UserDefaults.standard.bool(forKey: "SUHasLaunchedBefore") {
            updater.checkForUpdatesInBackground()
        }
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        updaterChannel.log("No updates pending.")
    }
    
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        updaterChannel.log("Found pending update \(item.displayVersionString ?? "(unknown version)").")
    }
    
    func updater(_ updater: SPUUpdater, willScheduleUpdateCheckAfterDelay delay: TimeInterval) {
        updaterChannel.log("Checking for update in \(Int(delay)) seconds.")
    }
}
