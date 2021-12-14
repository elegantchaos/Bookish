// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CloudKit
import Combine
import Files
import Logger
import SwiftUI
import SheetController

@main
struct Application: App {
    @Environment(\.scenePhase) var scenePhase

    let modelController: ModelController
    let lookupController: LookupManager
    let appearanceController: AppearanceController
    let importController: ImportController
    let sheetController: SheetController
    let statusController: StatusController
    
    init() {
        let undoManager = UndoManager()
        let stack = CoreDataStack(containerName: "BookishLists", undoManager: undoManager)
        self.modelController = ModelController(stack: stack)
        self.importController = ImportController(model: modelController)
        self.lookupController = LookupManager()
        self.sheetController = SheetController()
        self.appearanceController = AppearanceController()
        self.statusController = StatusController()

        if CommandLine.arguments.contains("--wipeAllData") {
            try? modelController.removeAllData()
            exit(0)
        }
        
        setupLookup()
    }
    
    func setupLookup() {
        lookupController.register(service: GoogleLookupService(name: "Google"))
    }
    
    
    var body: some Scene {
            return WindowGroup {
                ContentView()
                    .environment(\.managedObjectContext, modelController.stack.viewContext)
                    .environmentObject(modelController)
                    .environmentObject(sheetController)
                    .environmentObject(lookupController)
                    .environmentObject(appearanceController)
                    .environmentObject(importController)
                    .environmentObject(statusController)
                    .onReceive(
                        modelController.objectWillChange.debounce(for: .seconds(10), scheduler: RunLoop.main), perform: { _ in
                            print("model changed")
                            modelController.save()
                    })
            }
            .onChange(of: scenePhase) { newScenePhase in
                  switch newScenePhase {
                  case .active:
                    print("App is active")
                  case .inactive:
                    print("App is inactive")
                  case .background:
                    print("App is in background")
                    modelController.save()
                  @unknown default:
                    print("Oh - interesting: I received an unexpected new value.")
                  }
            }
    }
}
