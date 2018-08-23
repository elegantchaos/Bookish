//
//  AppDelegate.swift
//  Bookish
//
//  Created by Sam Deane on 17/08/2018.
//  Copyright © 2018 Elegant Chaos Limited. All rights reserved.
//

import Cocoa

protocol DocumentViewModel {
}

@NSApplicationMain
class Application: NSObject, NSApplicationDelegate {
    var documentBeingCreated: DocumentViewModel?

    static var sharedInstance: Application {
        return NSApp.delegate as! Application
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func createDocumentWindowController(with viewModel: DocumentViewModel, storyboard: String = "Main", identifier: String = "Document Window Controller") -> CollectionWindowController {
        assert(documentBeingCreated == nil)
        documentBeingCreated = viewModel
        let storyboard = NSStoryboard(name: NSStoryboard.Name(storyboard), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(identifier)) as! CollectionWindowController
        windowController.viewModel = (viewModel as! CollectionDocumentViewModel)
        documentBeingCreated = nil
        return windowController
    }
}

