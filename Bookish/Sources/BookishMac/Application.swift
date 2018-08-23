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
    private var documentBeingCreated: Any?

    static var sharedInstance: Application {
        return NSApp.delegate as! Application
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func createDocumentWindowController<VM: DocumentViewModel>(with viewModel: VM, storyboard: String = "Main", identifier: String = "Document Window Controller") -> VM.WindowController where VM.WindowController.ViewModel == VM {
        assert(documentBeingCreated == nil)
        documentBeingCreated = viewModel
        let storyboard = NSStoryboard(name: NSStoryboard.Name(storyboard), bundle: nil)
        var windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(identifier)) as! VM.WindowController
        windowController.viewModel = viewModel
        documentBeingCreated = nil
        return windowController
    }
    
    func connectViewModel<VM: DocumentViewModel>() -> VM {
        return documentBeingCreated as! VM
    }
}

