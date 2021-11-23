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
    let model: Model
    let lookup: LookupManager
    
    init() {
        let stack = CoreDataStack(containerName: "BookishLists")
        self.model = Model(stack: stack)
        self.lookup = LookupManager()

        if CommandLine.arguments.contains("--wipeAllData") {
            model.removeAllData()
            model.save()
            exit(0)
        }
        
        setupLookup()
    }
    
    func setupLookup() {
        lookup.register(service: GoogleLookupService(name: "Google"))
    }
    
    
    var body: some Scene {
            let sheetController = SheetController()
            return WindowGroup {
                ContentView()
                    .environment(\.managedObjectContext, model.stack.viewContext)
                    .environmentObject(model)
                    .environmentObject(sheetController)
                    .environmentObject(lookup)
                    .onReceive(
                        model.objectWillChange.debounce(for: .seconds(1), scheduler: RunLoop.main), perform: { _ in
                            model.save()
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
                    model.save()
                  @unknown default:
                    print("Oh - interesting: I received an unexpected new value.")
                  }
            }
    }
}
