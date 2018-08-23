//
//  AppDelegate.swift
//  Bookish
//
//  Created by Sam Deane on 17/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Cocoa

@NSApplicationMain
class Application: NSObject, NSApplicationDelegate {
    let documentWindowControllerFactory = DocumentWindowControllerFactory()
    
    static var sharedInstance: Application {
        return NSApp.delegate as! Application
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        ValueTransformer.setValueTransformer(AuthorsTransformer(), forName: AuthorsTransformer.name)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
