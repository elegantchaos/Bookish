// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Cocoa

@NSApplicationMain
class Application: NSObject, NSApplicationDelegate {
    let documentWindowControllerFactory = DocumentWindowControllerFactory()
    let uiTesting = CommandLine.arguments.contains("--ui-testing")
    
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
        
        ValueTransformer.setValueTransformer(AuthorsTransformer(), forName: AuthorsTransformer.name)
        ValueTransformer.setValueTransformer(DateTransformer(), forName: DateTransformer.name)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
