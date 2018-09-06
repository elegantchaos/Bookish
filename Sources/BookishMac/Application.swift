// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Cocoa

@NSApplicationMain
class Application: NSObject, NSApplicationDelegate, ActionContextProvider {
    let documentWindowControllerFactory = DocumentWindowControllerFactory()
    let actionManager = ActionManager()
    let uiTesting = CommandLine.arguments.contains("--ui-testing")
    var testDocument = CommandLine.arguments.contains("--test-document")
    let noBlankDocument = CommandLine.arguments.contains("--no-blank-document")
    
    override func awakeFromNib() {
        print(CommandLine.arguments)
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
        actionManager.register(action: TestAction(identifier: "TestAction"))
        actionManager.register(action: InsertPersonAction(identifier: "InsertPerson"))
        
        ValueTransformer.setValueTransformer(AuthorsTransformer(), forName: AuthorsTransformer.name)
        ValueTransformer.setValueTransformer(DateTransformer(), forName: DateTransformer.name)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return !noBlankDocument
    }
    
    @IBAction func performAction(_ sender: Any) {
        if let keyResponder = NSApplication.shared.keyWindow?.firstResponder, let actionID = (sender as? NSUserInterfaceItemIdentification)?.identifier?.rawValue {
            let context = ActionContext(target: keyResponder, sender: sender)
            actionManager.perform(action: actionID, context: context)
        }
    }
    
    func provide(context: ActionContext) {
        print("gathering context")
        context.info["Test"] = "Blah"
    }
}
