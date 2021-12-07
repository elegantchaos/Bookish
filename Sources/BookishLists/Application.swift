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

class AppearanceController: ObservableObject {
    func formatted(date: Date) -> String {
        let formatted = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
        return formatted
    }
}

@main
struct Application: App {
    @Environment(\.scenePhase) var scenePhase

    let model: Model
    let lookup: LookupManager
    let appearance: AppearanceController
    let sheetController = SheetController()

    init() {
        let undoManager = UndoManager()
        let stack = CoreDataStack(containerName: "BookishLists", undoManager: undoManager)

        self.model = Model(stack: stack)
        self.lookup = LookupManager()
        self.appearance = AppearanceController()

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
            return WindowGroup {
                ContentView()
                    .environment(\.managedObjectContext, model.stack.viewContext)
                    .environmentObject(model)
                    .environmentObject(sheetController)
                    .environmentObject(lookup)
                    .environmentObject(appearance)
                    .onReceive(
                        model.objectWillChange.debounce(for: .seconds(1), scheduler: RunLoop.main), perform: { _ in
                            print("model changed")
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
