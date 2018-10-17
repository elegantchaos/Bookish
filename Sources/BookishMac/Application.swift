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
class Application: NSObject, NSApplicationDelegate {
    let documentWindowControllerFactory = DocumentWindowControllerFactory()
    let actionManager = ActionManagerMac()
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
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        actionManager.register(PersonAction.standardActions())
        actionManager.register(PersonUIAction.standardActions())
        actionManager.register(BookAction.standardActions())
        actionManager.register([
            ShowDatePickerAction(identifier: "ShowDatePicker"),
            InsertItemAction(identifier: "InsertItem"),
            RemoveItemAction(identifier: "RemoveItem")
            ])
        
        actionManager.installResponder()

        BookishCore().test()
        
        ValueTransformer.setValueTransformer(AuthorsTransformer(), forName: AuthorsTransformer.name)
        ValueTransformer.setValueTransformer(DateTransformer(), forName: DateTransformer.name)
        ValueTransformer.setValueTransformer(CoverImageTransformer(), forName: CoverImageTransformer.name)
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
