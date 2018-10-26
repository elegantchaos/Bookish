// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Cocoa
import BookishCore
import BookishModel
import ActionsKit
import Logger

let applicationChannel = Logger("Application")

@NSApplicationMain
class Application: NSObject {
    let documentWindowControllerFactory = DocumentWindowControllerFactory()
    let actionManager = ActionManagerMac()
    let importManager = ImportManager()
    let uiTesting = CommandLine.arguments.contains("--ui-testing")
    var testDocument = CommandLine.arguments.contains("--test-document")
    let noBlankDocument = CommandLine.arguments.contains("--no-blank-document")
    
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
        actionManager.register(PersonAction.standardActions())
        actionManager.register(PersonUIAction.standardActions())
        actionManager.register(BookAction.standardActions())
        actionManager.register(ImporterAction.standardActions())
        actionManager.register([
            ShowDatePickerAction(identifier: "ShowDatePicker"),
            InsertItemAction(identifier: "InsertItem"),
            RemoveItemAction(identifier: "RemoveItem")
            ])
        
        actionManager.installResponder()
    }
    
    fileprivate func setupTransformers() {
        ValueTransformer.setValueTransformer(AuthorsTransformer(), forName: AuthorsTransformer.name)
        ValueTransformer.setValueTransformer(DateTransformer(), forName: DateTransformer.name)
        ValueTransformer.setValueTransformer(ImageTransformer(placeholder: "CoverPlaceholder"), forName: NSValueTransformerName("CoverImage"))
        ValueTransformer.setValueTransformer(ImageTransformer(placeholder: "PersonPlaceholder"), forName: NSValueTransformerName("PersonImage"))
    }
}

extension Application: NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        BookishCore().test()

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
