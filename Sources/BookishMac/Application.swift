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

let applicationChannel = Logger("Application")

@NSApplicationMain class Application: NSObject {
    
    let documentWindowControllerFactory = DocumentWindowControllerFactory()
    let actionManager = ActionManagerMac()
    let importManager = ImportManager()
    let imageCache = NSImageCache()
    
    let uiTesting = CommandLine.arguments.contains("--ui-testing")
    var testDocument = CommandLine.arguments.contains("--test-document")
    let noBlankDocument = CommandLine.arguments.contains("--no-blank-document")
    
    var watchedMenuItem: NSMenuItem?
    
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
        actionManager.register(ModeAction.standardActions())
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
        ValueTransformer.setValueTransformer(ImageTransformer(placeholder: "CoverPlaceholder", cache: imageCache), forName: NSValueTransformerName("CoverImage"))
        ValueTransformer.setValueTransformer(ImageTransformer(placeholder: "PersonPlaceholder", cache: imageCache), forName: NSValueTransformerName("PersonImage"))
    }
}

extension Application: NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        setupActions()
        setupTransformers()
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
}

extension Application: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(delete(_:)) {
            // special case for the Delete menu item in the Edit menu
            // we want to leave the action as the default, so that it works in controls in the normal
            // way, but when it falls down lower we want to map it to the DeleteItem action
            let validation = Application.sharedInstance.actionManager.validate(identifier: "DeleteItem", info: ActionInfo(sender: menuItem))
            menuItem.title = validation.name ?? "Delete"
            
            watchForDeleteItemClosing(item: menuItem)
            return validation.enabled
        }
        return false
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
